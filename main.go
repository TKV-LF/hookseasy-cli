package main

import (
	"bufio"
	"bytes"
	"crypto/tls"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"strings"
	"sync"
	"time"

	"github.com/progrium/qmux/golang/session"
)

type timeoutReader struct {
	net.Conn
	once sync.Once
}

func (r *timeoutReader) Read(b []byte) (int, error) {
	n, err := r.Conn.Read(b)

	// Set a Read TimeOut only after the first Read completes
	// If timed out, treat it as an io.EOF so the bufio.Scanner handles
	r.once.Do(func() {
		r.Conn.SetReadDeadline(time.Now().Add(6 * time.Second))
	})

	// the error as if it was the normal end of the stream.
	var netErr net.Error
	if errors.As(err, &netErr) && netErr.Timeout() {
		return n, io.EOF
	}
	return n, err
}

func main() {
	var host = flag.String("host", "tunnel-register.hookseasy.com", "server hostname to use")
	var port = flag.String("p", "443", "server port to use")

	// server args
	var token = flag.String("t", "", "token to identify the user")
	var target_host = flag.String("h", "", "Target host into which the webhook goes")
	var is_https = flag.Bool("https", false, "")
	var cookie = flag.String("cookie", "", "Set cookie")
	flag.Parse()

	if *token == "" {
		log.Fatal("Token is required. Use -t flag to input your token.")
	}

	if *target_host == "" {
		log.Fatal("Target host is required. Use -h flag to input your target host at you local.\nFor example: -h localhost:8080")
	}

	// client usage: groktunnel [-h=<server hostname>] <local port>
	for {
		fmt.Println("")
		loop(*host, *port, *token, *target_host, *is_https, *cookie)
		fmt.Println("Reconnecting...")
		time.Sleep(2 * time.Second)

	}
}

func loop(host, port, token, target_host string, is_https bool, cookie string) {
	fmt.Println("---")
	conf := &tls.Config{
		InsecureSkipVerify: true,
	}
	conn, err := tls.Dial("tcp", net.JoinHostPort(host, port), conf) // connect to server
	if err != nil {
		fmt.Println("Error 1:")
		fmt.Println(err)
		return
	}

	client := httputil.NewClientConn(conn, bufio.NewReader(conn)) // create HTTP request (can be hijacked)
	form_data := bytes.NewBuffer([]byte(fmt.Sprintf("token=%s", token)))
	req, err := http.NewRequest("POST", "/", form_data)
	if err != nil {
		fmt.Println("Error 2")
		log.Fatal(err)
	}

	req.Header = map[string][]string{
		"Content-Type": {"application/x-www-form-urlencoded"},
	}
	req.Host = host
	client.Write(req)

	resp, _ := client.Read(req)

	if resp.StatusCode >= 400 {
		fmt.Printf("Invalid input")
		return
	}

	fmt.Printf("Your target_host %s is available at:\n", target_host)
	fmt.Printf("* https://%s *\n", resp.Header.Get("X-Public-Host"))

	c, _ := client.Hijack() // Detach Client connection
	sess := session.New(c)  // create qmux session,this is the tunnel
	defer sess.Close()
	for { // waiting for incoming channels
		ch, err := sess.Accept()
		if err != nil {
			fmt.Println(err)
			fmt.Println("Error: channel cannot initiated")
			return
		}
		defer ch.Close()

		var conn net.Conn
		if is_https {
			conn, err = tls.Dial("tcp", target_host+":https", conf)
			if err != nil {
				fmt.Println(err)
				log.Fatal("Error 3")
			}
		} else {
			conn, err = net.Dial("tcp", target_host)
			if err != nil {
				fmt.Println(err)
				log.Fatal("Error: *target_host* not found")
			}
		}

		go func() {
			scanner := bufio.NewScanner(ch)
			for scanner.Scan() {
				line := scanner.Text()
				split := strings.Split(line, " ")
				if split[0] == "Host:" {
					conn.Write([]byte("Host: " + target_host + "\r\n"))
					if len(cookie) > 0 {
						conn.Write([]byte("Cookie: " + cookie + "\r\n"))
					}
				} else {
					conn.Write([]byte(line + "\r\n"))
				}
			}

			scanner2 := bufio.NewScanner(&timeoutReader{Conn: conn})
			buf := make([]byte, 0, 64*1024)
			scanner2.Buffer(buf, 2*1024*1024)
			for scanner2.Scan() {
				line := scanner2.Text()
				ch.Write([]byte(line + "\r\n"))
				fmt.Println(line)
			}

			conn.Close()
		}()
	}
}
