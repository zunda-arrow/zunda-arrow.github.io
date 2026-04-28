---
layout: ../../layouts/blog_post.astro
title: How do Sockets Work?
published-on: 04/26/2026
---

In every modern text editor, there is support for Language Server Processors (LSP).
These are that tool that provide error and warnings for a language in your text editor.
One way we can make this communcation possible is having our LSP and text editor read and write to files they both agree on.

```
              -------------------
      Write   |                 |  Read
 LSP -------> |  Shared File A  | -------> Text Editor
              |                 |
              -------------------
              -------------------
       Read   |                 |  Write
 LSP <------- |  Shared File B  | <------- Text Editor
              |                 |
              -------------------
```
With this system, LSP can write to "Shared File A" to send a message to Text Editor.
Text Editor can write to "Shared File B" to send a message to LSP.


This is the foundation for socket communication.
Next we need a way to open the socket.
Note that a text editor always starts before the LSP.
The text editor can also attach to multiple LSPs at the same time, if we are programming in multiple languages.

That implies that we want our text editor to be listening for LSP to ask for a connection.
Our text editor is known as the socket server because it is listening for connections and can be connected to multiple LSPs.
The LSP is the client because it does not listen for connections and can only connect to one text editor.

```
                       -------------------
      Write `/tmp/a`   |                 |
 LSP ----------------> |    /tmp/recv    |
                       |                 |
                       -------------------
                               |
                               |  Read
                               v
     Text editor creates `/tmp/b` writes `/tmp/b` to `/tmp/a`
```


This is enough to implement a basic socket using the file system. Here's a program
that tries our method out in python.

```python
import os
import threading
import time

# These three files are used by the server and client
# New processes that want to connect write their file path to LISTEN_TO_CONNECTIONS.
LISTEN_TO_CONNECTIONS = "/tmp/recv"
# Messages that should be send to the client are written to FILE_A.
FILE_A = "/tmp/a"
# Messages that should be send to the server are written to FILE_B.
FILE_B = "/tmp/b"

# Ensure files exist, so we can read from them
open(LISTEN_TO_CONNECTIONS, "w")
open(FILE_A, "w")
open(FILE_B, "w")

def socket_server():
    print("Waiting for connection...")
    with open(LISTEN_TO_CONNECTIONS, "r") as f:
        f.seek(0, 2) # Seek to the end of the file, so we only accept new messages
        while True:
            next_file = f.readline()
            if (not next_file):
                time.sleep(1)
                continue
            threading.Thread(target=handle_connection, args=[next_file]).run()
            break

def handle_connection(next_file):
    print(f"Found connection at {next_file}")

    with open(next_file, "a") as f:
        f.write(FILE_B)

    with open(FILE_B, "r") as f:
        f.seek(0, 2) # Seek to the end of the file, so we only accept new messages
        while True:
            msg = f.readline()
            if not msg:
                time.sleep(1)
                continue
            print(f"Recieved message: {msg}")

def socket_client():
    print("Starting client...")
    with open(LISTEN_TO_CONNECTIONS, "a") as f:
        f.write(FILE_A)

    # The server should respond on file A, the name of their file
    file = None
    with open(FILE_A, "r") as f:
        f.seek(0, 2) # Seek to the end of the file, so we only accept new messages
        while True:
            file = f.readline()
            if not file:
                time.sleep(1)
                continue
            break

    print(f"Connected on {file}")

    # Send the message "Hello World" to the server
    with open(file, "a") as f:
        f.write("Hello World")

# Start our server and client
server = threading.Thread(target=socket_server)
server.start()
client = threading.Thread(target=socket_client)
client.start()
```
The output of this program is:
```
[server] Waiting for connection...
[client] Starting client...
[server] Found connection at /tmp/a
[client] Connected on /tmp/b
[server] Recieved message: Hello World
```

After implementing this we can see there is a 2 big issues.
1. Using our file system is slow.
2. We need to seek to the end of each file before we try reading the next message, or we might read an old message.



First lets tackle using our file system.
Its great that we can read and write to a file to use our sockets, but writing to the disc is extremely slow.
Linux provides a solution to this with a struct called `file_operations` `linux/fs.h:1926`. Instead of reading
and writing to our usual file system we can make a custom file type. We can have this custom file type read
and write into ram instead of our disc by providing a `read_iter` and `write_iter` method.

`net/socket.c:157`
```
struct const file_operations socket_file_ops  = {
	<...>
	.read_iter =	sock_read_iter,
	.write_iter =	sock_write_iter,
	<...>
}
```

This lets us use the usual file operations we are used to, but when we read and write it will be from ram instead.

Problem 2 is also easy. Instead of using a file where we can write or read to any point, we can use whats called a "stream file".
With stream files, we can only read or write directly to the end of the file because seeking is not
possible. This is good. That means that when someone reads or writes to our socket file, they will always be right at
the end.

## STOP HERE



```
                               Application Layer
            --------------------------------------------------------
            |                   Transport Layer                    |
            |                ----------------------                |
            |                |                    |                |
            |   ----------   |    Write to each   |   ----------   |
Program A <---> | File A | <--->  other's file  <---> | File B | <---> Program B
            |   ----------   |                    |   ----------   |
            |                ----------------------                |
            |                   (Socket Modules)                   |
            --------------------------------------------------------
```



Network socket diagram
```
                               Application Layer
            --------------------------------------------------------
            |                   Transport Layer                    |
            |                ----------------------                |
            |                |   Network Layer    |                |
            |   ----------   |      & Below       |   ----------   |
Program A <---> | File A | <--->                <---> | File B | <---> Program B
            |   ----------   |   (INET Modules)   |   ----------   |
            |                ----------------------                |
            |                   (Socket Modules)                   |
            --------------------------------------------------------
```



## This file isn't a file on disc


## The Socket Syscall
When we create a socket


When creating a socket, a file is eventually allocated. This file is a litte strange, because it fills a few properties:

1. Reading and writing might need to go through the network interface.
2. Seeking is not allowed.
3. If we attempt to read and write at the same time, our file isn't corrupted.

`net/socket.c:157`
```
struct const file_operations socket_file_ops  = {
	<...>
	.read_iter =	sock_read_iter,
	.write_iter =	sock_write_iter,
	<...>
}
```

These two functions


For requirement 3, we use the file options `O_NONBLOCK`.

```
int sending_thread(sock_fd) {
	u8[] buf = "hello world";
	int bufsize = strlen(buf);
	write(fd, buf);
}

int listening_thread(sock_fd) {
	u8[512] buf;
	read(fd, buf, 512);
}
```


`stream_open` (`fs/open.c:1574`) opens a file with the open syscall, in stream mode.



For a regular file, only one process can have the file opened at the same time. That means that
if we start `write`, it will block the `read` function until write finishes, and vise-versa.
But, with sockets, we may want one thread always reading from the socket file while another
thread is incharge of writing to the socket. `O_NONBLOCK` lets you use multiple read or multiple
write functions at the same time, only blocking while a write or read is happening.
This is the bare minimum requirement to prevent a race condition, our socket being corrupted due to data being read and written at the same time.

`net/socket.c:536`
```
struct file *sock_alloc_file(struct socket *sock, int flags, const char *dname)
{
	struct file *file;
	<...>
	file = alloc_file_pseudo(SOCK_INODE(sock), sock_mnt, dname,
				O_RDWR | (flags & O_NONBLOCK),
				&socket_file_ops);
	<...>
	sock->file = file;
	<...>
	stream_open(SOCK_INODE(sock), file);
	<...>
	return file;
}
```


`net/socket.c:1818`
```
SYSCALL_DEFINE3(socket, int, family, int, type, int, protocol)
{
	return __sys_socket(family, type, protocol);
}
```



`fs/open.c:1574`
```
/*
 * stream_open is used by subsystems that want stream-like file descriptors.
 * Such file descriptors are not seekable and don't have notion of position
 * (file.f_pos is always 0 and ppos passed to .read()/.write() is always NULL).
 * Contrary to file descriptors of other regular files, .read() and .write()
 * can run simultaneously.
 *
 * stream_open never fails and is marked to return int so that it could be
 * directly used as file_operations.open .
 */
int stream_open(struct inode *inode, struct file *filp)
{
	filp->f_mode &= ~(FMODE_LSEEK | FMODE_PREAD | FMODE_PWRITE | FMODE_ATOMIC_POS);
	filp->f_mode |= FMODE_STREAM;
	return 0;
}
```


