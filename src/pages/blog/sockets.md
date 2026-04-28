---
layout: ../../layouts/blog_post.astro
title: How do Sockets Work?
published-on: 04/26/2026
---

*This article is written for linux kernel commit `20b64c`. Follow along [here!](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/?id=20b64cf)*


In every modern text editor, there is support for Language Server Processors (LSP).
These are tools that provide error and warnings for a language in your text editor.
One way we can make this communication possible is by having our LSP and text editor read and write to files they have both agreed on.

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


It is important for text editor to be able to attach to multiple LSPs at the same time.
This is required if we are programming in multiple languages, where each language has an LSP.

That implies that we want our text editor to be listening for LSP to ask for a connection.
Our text editor is known as the socket server because it is listening for connections and can be connected to multiple LSPs.
LSP is the client because it does not listen for connections and can only connect to one text editor.

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
            print(f"Received message: {msg}")

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
[server] Received message: Hello World
```

After implementing this we can see there is two big issues.
1. Using our file system is slow.
2. We need to seek to the end of each file before we try reading the next message, or we might read an old message.



First lets tackle using our file system.
Its great that we can read and write to a file to use our sockets, but writing to the disc is extremely slow.
Linux provides a solution to this with a struct called `file_operations` `linux/fs.h:1926`. Instead of reading
and writing to our usual file system we can make a custom file type. We can have this custom file type read
and write into memory instead of our disc by providing a `read_iter` and `write_iter` method.

We want to write and read to some sort of data structure in memory that can be written and read by multiple
processes without breaking. The data structure also needs to be able to expand without reaching a max size.
This structure ends up being an async array list. Another way to phrase our goal, is we want writing and reading
to our socket to eventually funnel down to an async array list.

This is code is used to create sockets by the linux kernel at `net/socket.c:157`.
```c
struct const file_operations socket_file_ops  = {
	<...>
	.read_iter =	sock_read_iter,
	.write_iter =	sock_write_iter,
	<...>
}
```

This lets us use the usual file operations we are used to, but when we read and write it will be from memory instead.

Problem 2 is also easy. Instead of using a file where we can write or read to any point, we can use what's called a "stream file".
With stream files, seeking is not possible, so we can only read or write directly at end of the file
This is good.
That means that when a process reads or writes to our socket file, they will always be right at the end.

Linux uses the function `stream_open` at `fs/open.c:1574` for this purpose. "fmode" stands for "file mode" in the following code block.
"inode" is the `file operations` struct we looked at earlier plus a few fields that are not important for this topic.
```c
int stream_open(struct inode *inode, struct file *flip)
{
	filp->f_mode &= ~(FMODE_LSEEK | FMODE_PREAD | FMODE_PWRITE | FMODE_ATOMIC_POS);
	filp->f_mode |= FMODE_STREAM;
	return 0;
}
```

Stream files have a second bonus ability, they can be written to and read from simultaneously.
This is important because it lets our socket send and receive messages over the same socket file at the same time.


## Tracing The Syscall
The socket syscall, or asking the linux kernel to open a socket goes through the steps previously mentioned.

This function is the entrypoint, or the first function that is called by the socket syscall.
This syscall is called by the function `socket(int socket, int family, int protocol)`.

`net/socket.c:1818`
```c
SYSCALL_DEFINE3(socket, int, family, int, type, int, protocol)
{
	return __sys_socket(family, type, protocol);
}
```

Heres an example of using this syscall to create a unix socket, the type of socket used to communicate between programs.
```c
#include <sys/socket.h>

int main() {
	int fd = socket(AF_UNIX, SOCK_STREAM, 0);
}
```

The function `sock_alloc_file` is eventually called. This function creates a file with the properties
we discussed earlier. The file lives entirely in memory and is a stream file.

`net/socket.c:536`
```c
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
```

The argument `struct socket *sock` is a structure defined as so:

`include/linux/net.h:137`
```c
struct socket {
	<...>
	struct file		*file;
	<...>
	struct socket_wq	wq;
};
```

`socket_wq` is a buffer that all incoming data will be written to. It is a wrapper around the `fasync_list`
linux primitive. The important thing here is that this functions like a array list in that we can write as much
information to it without overflowing.

Next, lets take a look into reading and writing to this socket.
If we trace the functions called when we use read or write on a socket file descriptor,
we will eventually call a function on a struct called `proto_ops` defined in `include/linux/net.h:181`.
This structure is how the linux kernel defines socket types to be used with the functions provided by "<sys/socket.h>".
The following is a struct that defines what functions are used to send and receive messages for unix sockets.

`net/unix/af_unix.c:966`
```c
static const struct proto_ops unix_stream_ops = {
	<...>
	.sendmsg =	unix_stream_sendmsg,
	.recvmsg =	unix_stream_recvmsg,
	<...>
};
```

Lets take a look at the `.sendmsg` and `.recvmsg` on `unix_stream_ops` to see how a unix SOCK_STREAM sends and receives data.

The following function is unix sendmsg.

- "sk" stands for "socket".
- "skb" stands for "socket buffer".
- "outheru" stands for "other unix socket"
- "inq_len" stands for "input queue length"

`net/unix/af_unix.c:2381`
```c
static int unix_stream_sendmsg(struct socket *sock, struct msghdr *msg, size_t len)
{
	struct sock *sk = sock->sk;
	struct sk_buff *skb = NULL;
	struct sock *other = NULL;
	struct unix_sock *otheru;
	<...>
	// `other` is set by looking a global table that maps file descriptors to socket structures.
	otheru = unix_sk(other);
	<...>
	
	while (sent < len) {
		int size = len - sent;
		int data_len;
		<...>
		spin_lock(&other->sk_receive_queue.lock); // Prevent other threads from modifying the buffer
		WRITE_ONCE(otheru->inq_len, otheru->inq_len + skb->len); // The same as otheru->inq_len = otheru->inq_len + skb->len
		__skb_queue_tail(&other->sk_receive_queue, skb);
		spin_unlock(&other->sk_receive_queue.lock); // Allow other threads to modify the buffer again
		<...>
	}
	<...>
}
```

*WRITE_ONCE and READ_ONCE are macros to write and read pointers in a threadsafe manner. This is not important for this explanation.*


The `__skb_queue_tail` function, also known as "socket buffer queue tail" does the magic. This function pushes the data
we want to send to the `socket_wq` list.
When we write to one of the socket files, we go through a ton of code just to push to this the data to our receivers array list.

When we read the socket we eventually make our way to a function called `unix_stream_read_generic net/unix/af_unix.c:2913`.
This functions stalls the thread until information is written to our buffer. Then, we return that buffer.

After seeing that sockets are really just an array list with a bunch of fancy code around it, it makes you ask
the question of why we bothered with a file in the first place. I think there isn't a clear answer to this, but to
me we bothered with files so that we can follow the unix philosaphy of "everything is a file". There are concrete
advantages though, such that sockets can use file system security features that are already available, and that we can easily
expand this interface to work with sending data over a network.


## From Local Sockets to Network Sockets

First, a refresher on the OSI network model. We use sockets from the application layer,
and they are implemented at the transport layer. The goal of the transport layer is to
move data from the application layer to network layer. The data link and physical layers
are not relevant for sockets.

```
-------------------------------
|         Application         |
-------------------------------
  |        Transport        |
  ---------------------------
    |       Network       |
    -----------------------
      |    Data Link    |
      -------------------
        |   Physical  |
        ---------------
````

Heres a diagam of of how our current sockets communicate.

```
                                  Application
            --------------------------------------------------------
            |                   Write to socket                    |
            |                ----------------------                |
            |                |                    |                |
            |   ----------   |    Write to each   |   ----------   |
Program A <---> | File A | <--->  other's file  <---> | File B | <---> Program B
            |   ----------   |                    |   ----------   |
            |                ----------------------                |
            |                   (Socket Modules)                   |
            --------------------------------------------------------
```


Fortunately this already resembles how we want sockets to work with the OSI network model.
The way the application uses sockets does not need to change at all, we are still
going to write to files. The transport layer will require a slight change.
Instead of writing from one file to antother locally, we will send the data over the network layer.

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

Once our receiver receives our buffer, they can write it to their local array list. Then, the receiver is able to read it
like a regular file. This interface has completely hid the network stack from both applications. It looks identical to writing
and reading to a regular file.


## In Conclusion

The way sockets are implemented in the linux kernel seems needlessly complex at first glance.
But what we have gained from all this work is a system that lets anything from LSPs and text editors that
communicate locally to web servers across the world communicate in the exact same way. The power
that comes from this is impossible to overstate.

Although its complecated to use sockets at first, once you can use any of the socket types you
can do any time of communication between programs or systems with little effort. A practical
example of this is programs such as [tmux](https://github.com/tmux/tmux), that work locally or even between computers. It's 
an amazing system.

