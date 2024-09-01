---
layout: ../../layouts/blog_post.astro
title: Introduting Aporia, a Window Manager for X11 and Wayland
published-on: 09/01/2024
---

A bit over a year ago, I started development of my window manager, [Aporia](https://github.com/Lunarmagpie/aporia).
As someone who loves the command line, I wanted to be able to log in without a graphical interface but none of the
options at the time had the visuals that I wanted. Although I love the progrom [Ly](https://github.com/fairyglade/ly)
written by FairyGlade, the visuals became boring to me after a while. I was also wanting to do something above my skill
level so this project seemed to be a good fit.

Aporia is desinged for one feature: displaying ascii art in the background when you log in. The most important part
of using Linux is to make your computer look like a hacker's computer, and I think this project totally smashes
that goal.

## Aporia 0.1.0

Today, I'm launching Aporia 0.1.0. After a look of work and testing from myself its become pretty stable. Aporia has
nice features like Automatic desktop detection, and I believe Aporira has the simplest way to add your own desktop
session launch scripts out of any window manager. On my laptop, I haven't picked an ascii-background yet, but I
still use Aporia just for this feature. Please use the project and email me a picture!

## Developing A Login Manager

Although Aporia took me a long time to get completely stable, I was able to get the project up and running extremely
quickly. The first secret to that was the great resource by for how to write a login manager written by
[Gsgx](https://gsgx.me/posts/how-to-write-a-display-manager/). Their guide is extremely in depth and covers a ton of
edge cases. I also read the source code for Ly. A large thank you to FairyGlade making their project open source. I
wouldn't have been able to finish Aporia so quickly without it. I put Aporia under WTFPL so other people can use my work
like I used the past work from others :). Please liberally steal code snippits.

The second secret to launching finishing the initial versions of this project quickly was Go. I decided to use Golang
because I wanted to learn a new language. I found that his language was so easy that I was able to understand
code examples in the documentation immediately and was not bogged down by understanding language semantics (looking
at you Rust).

I also found CGO incredibly simple to work with. I have heard that Cgo is difficult to use but I have to disagree. As
someone who was new to Go and had very limited experience with C, I found it quite easy to work with. Because Cgo does
not include any custom syntax the examples simply make sense. The only "gacha" I ran into when working with Cgo is that
you can not pass lambda functions as an argument to a C function. Fortunately static functions can be passed as callbacks
so it is not a big issue.

## Dbus and X11

I feel I need to dedicate a section to complaining about dbus and x11. The startx script that shipped with Popos back when I developed Aporia
initally included the line `unset DBUS_SESSION_BUS_ADDRESS`. This clearly breaks dbus and caused me quite a large amount
of pain. I do not know why the startx script includes this line, as disabling fixed all the issues I was having with
X11 and dbus. X11 has the most bespoke and confusing way of starting a process as well, which is why I decided to ship Aporia with a
modified version of startx instead of programming the launch script myself. Why can't it just be simple like Wayland?
X11 support was legitmately the biggest time cost on this project and I didn't know go before I started this project.

## Try it out Yourself

Give my login manager a shot, its pretty good! You can install it with the
[instructions in the README](https://github.com/Lunarmagpie/aporia?tab=readme-ov-file#compilation--installtion).

