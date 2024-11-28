package main

import (
	"bufio"
	"bytes"
	"crypto/tls"
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"strings"

	"github.com/progrium/qmux/golang/session"
)

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

	conf := &tls.Config{
		InsecureSkipVerify: true,
	}
	conn, err := tls.Dial("tcp", net.JoinHostPort(*host, *port), conf) // connect to server
	if err != nil {
		fmt.Println(err)
		log.Fatal("Error 1")
	}
	
	client := httputil.NewClientConn(conn, bufio.NewReader(conn)) // create HTTP request (can be hijacked)
	log.Printf("token=%s", *token)
	log.Printf("It's just a test")
	return
	form_data := bytes.NewBuffer([]byte(fmt.Sprintf("token=%s", *token)))
	req, err := http.NewRequest("POST", "/", form_data)
	if err != nil {
		fmt.Println(err)
		log.Fatal("Error 2")
	}

	req.Header = map[string][]string{
		"Content-Type": {"application/x-www-form-urlencoded"},
	}
	req.Host = *host
	client.Write(req)

	resp, _ := client.Read(req)

	if resp.StatusCode >= 400 {
		log.Printf("Invalid input")
		return
	}

	fmt.Printf("target_host %s available at:\n", *target_host)
	fmt.Printf("https://%s\n", resp.Header.Get("X-Public-Host"))

	c, _ := client.Hijack() // Detach Client connection
	sess := session.New(c)  // create qmux session,this is the tunnel
	defer sess.Close()
	for { // waiting for incoming channels
		ch, err := sess.Accept()

		var conn net.Conn
		if *is_https {
			conn, err = tls.Dial("tcp", *target_host+":https", conf)
			if err != nil {
				fmt.Println(err)
				log.Fatal("Error 3")
			}
		} else {
			conn, err = net.Dial("tcp", *target_host)
			if err != nil {
				fmt.Println(err)
				log.Fatal("Error 4")
			}
		}

		go func() {
			scanner := bufio.NewScanner(ch)
			for scanner.Scan() {
				line := scanner.Text()
				split := strings.Split(line, " ")
				if split[0] == "Host:" {
					conn.Write([]byte("Host: " + *target_host + "\r\n"))
					if len(*cookie) > 0 {
						conn.Write([]byte("Cookie: " + *cookie + "\r\n"))
					}
				} else {
					conn.Write([]byte(line + "\r\n"))
				}
			}

			scanner2 := bufio.NewScanner(conn)
			buf := make([]byte, 0, 64*1024)
			scanner2.Buffer(buf, 2*1024*1024)
			for scanner2.Scan() {
				line := scanner2.Text()
				ch.Write([]byte(line + "\r\n"))
				log.Println(line)
			}

			conn.Close()
			ch.Close()

		}()
	}
}
