---
layout: ../layouts/blog_post.astro
title: You can't write clean code without OOP
---

OOP is hated by a lot of programmers. They'll tell you inheritence
produces bad code, or that objects hide control flow. I think this
misses the point of object-oriented programming. Its a paradeigm
that helps you encapsulate side effects by using "message-passing"
to help improve legibility of code.

## OOP isn't about Inheritence
Nobody likes inheritene.


## What exactly is message passing?
An obvious form a message passing is communication between a client
and server. When the server sends a message to the client it doesn't know
whats going on in the client's code. It is just expacted a message to
be recieved based on a **predefined protocol**. Similarly the client
will expect messages from the server based on a protocol. It doesn't
need to know the inner workings of the server.

Now instead of pretending that both the client and server are a process, 
pretend that they are two classes in an object oriented code. Heres an
example of a server object that holds references to a map of client
objects.


```python
class Server:
  def __init__(self):
    self.clients: dict[str, Client] = {}


  def foo():
    response = self.client[client_id].send_message("hello")

class Client:
  def send_message(message: str) -> str:
    return message
```

In this example we have a server that sends a message to a client
and the client will respond with the same result. This example is a
bit esoteric, but it shows a client and server commuticating without
knowing what each one does.

## Hidden State Changes
Hidden state changes are scary. A reason people love FP so much is
that state changes can't be hidden (or can they...). Hidden state
changes are extremely powerful when used properly though.

Lets say that the client wants to keep track of the amount of messages
that the server sent to it. It would be ludicrous for our server to
worry about that because the amount of messages the client recieved
doesn't matter to the server. So lets make a new `send_message` function:

```python
class Client:
  def __init__(self):
    self._messages_recieved = 0

  def send_message(message: str) -> str:
    self._messages_recieved += 1
    return message
```

Maybe for some reason the server does want the `_messages_recieved` variable.
In classic OOP fashion we make a public method to wrap our private
attributes.

## Privacy
The reason we have privacy in OOP is so a random object can't muck up
our state. I think modifying a public a public field on a `struct` in
rust as a code smell because we just added a place where state is
changed that other programmers aren't expected it to be changed.

## Immutable from the Outside
All objects should only mutate themselves internally. To an observer there
shouldn't be a change.


## A word about Inheritence
Fuck inheritence.


## Conclusion
In conclusion OOP is based for scaleable software.
