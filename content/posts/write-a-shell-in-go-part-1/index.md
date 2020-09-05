+++
title = "Write a shell in Go (Part 1)"
description = "Write a Linux shell using go programming language"
tags = [
    "go",
    "golang",
    "templates",
    "themes",
    "development",
]
date = "2019-11-02"
categories = [
    "Go",
]
menu = "main"
+++

If you are a programmer, shells are an integral part of your daily life. Writing a shell from scratch is a great exercise to understand the workings of a shell. In this series, we are going to write a reasonably functional linux shell in Go. The source code for this project can be found on github [here](https://github.com/jerilseb/gush).

In a nutshell, a shell is basically a command interpreter. You type in a command and the shell does something in response. So to start off, let's create a REPL (Read, Evaluate, Print Loop) using an infinte `for` loop. This will allow us to type in commands to the shell. For now, we will read a line and just print it. As a shell prompt, we will print the shell name and give some flair to it using an [ANSI escape sequence](https://en.wikipedia.org/wiki/ANSI_escape_code). You can see all ANSI codes for controlling the terminal [here](http://ascii-table.com/ansi-escape-sequences.php). Create a file `main.go` with the following contents.

```go
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	for {
		fmt.Printf("\033[36mgush \033[36m\u2713 \033[m")
		reader := bufio.NewReader(os.Stdin)

		c, _, _ := reader.ReadLine()
		fmt.Println(string(c))
	}
}
```

If you run the program using `go run main.go`, you should see our shell prompt. Type in some text and press **Enter**. You'll see the text getting printed back to the console. Now try pressing the up arrow key. You'll see the terminal cursor jumping up a line and starting to overwrite the line. This is because, by default, your terminal starts in **canonical mode** (_also known as **cooked** mode_). In this mode, any input we type into the terminal is immediately echoed back onto the terminal and is only sent to the program when the `Enter` key is pressed. For a shell program, we need to have  control over each keystroke. You can exit the program by pressing `Ctrl + C`.

To gain more control over the terminal, we have to change our terminal mode into something known as the [Raw Mode](https://en.wikipedia.org/wiki/Terminal_mode). In this mode, we get very fine control over the terminal. You can read more about entering raw mode [here](https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html). As of this writing, Go doesn't have any builtin way of changing the terminal's mode. But the good news is that all modern Unix systems come with an API called [termios](https://en.wikibooks.org/wiki/Serial_Programming/termios) for controlling terminal I/O, which is exposed through the C header file `termios.h`. So for changing modes, we can write some C code and call it from Go using [cgo](https://golang.org/cmd/cgo/). Let's create a file called `rawmode.c` as shown below
```c
‏‏‎ ‎#include <stdlib.h>
‏‏‎ ‎#include <termios.h>
‏‏‎ ‎#include <unistd.h>

struct termios orig_termios;

void disableRawMode() {
	tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
}

void enableRawMode() {
	tcgetattr(STDIN_FILENO, &orig_termios);
	struct termios raw = orig_termios;
	raw.c_lflag &= ~(ECHO | ICANON | ISIG);
	tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
}
```

We have defined 2 functions `disableRawMode()` and `enableRawMode()` to disable and enable the terminal raw mode. Along with entering raw mode, we do 2 other things. We turn off terminal echoing and processing of control signals like `Ctrl+C`. This is achieved by using the termios flags `~(ECHO | ICANON | ISIG)`. Now it's up to us to process each character as we wish. Let's import the functions into our Go code using cgo.

```go {hl_lines=["3-7"]}
package main

/*
extern void disableRawMode();
extern void enableRawMode();
*/
import "C"

import (
	"bufio"
	"fmt"
	"os"
)
```

Let's define a function `exit` to disable rawmode whenever we exit the program.

```go
func exit() {
	C.disableRawMode()
	os.Exit(0)
}
```

Instead of reading a line, we'll read character-by-character in an infinite for-loop and print each character as it is read. Also when we enabled raw-mode, we disabled control signals such as `Ctrl+C`. So we need a way to exit the shell. Let's handle `Ctrl+C` (character code 3) keypress ourselves.

```go {hl_lines=["5-18"]}
func main() {
	for {
		fmt.Printf("\033[36mgush \033[36m\u2713 \033[m")
		reader := bufio.NewReader(os.Stdin)
		C.enableRawMode()

		for {
			c, _ := reader.ReadByte()

			// Ctrl+C is pressed
			if c == 3 {
				fmt.Println("Exiting...")
				exit()
			}

			fmt.Printf("%c", c)
		}
	}
}
```

You can build and run the program using `go build`. Also, let's create a Makefile to make our build process easier. If you are unfamiliar with Makefiles, [here](https://opensource.com/article/18/8/what-how-makefile) is a handy primer. Below is simple Makefile which can be used for building any go program.

```makefile
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
BINARY_NAME=gush

all: build
build: 
		$(GOBUILD) -o $(BINARY_NAME)
clean: 
		$(GOCLEAN)
		rm -f $(BINARY_NAME)
run:
		$(GOBUILD) -o $(BINARY_NAME)
		./$(BINARY_NAME)
```

Build the program using `make` command. It will generate an executable in the same directory. You can run the program using `make run` as well.

You'll notice that we still haven't solved our backspace issue. Let's do that now. We'll define a variable called `line` to keep the contents of the current line the user is typing. Also define a variable called `cursorPos` to keep track of the position of the cursor within the line. Anytime a character is typed, we'll print the character, advance `cursorPos` and append the character to `line`. When backspace is pressed we'll use the ANSI escape code `\033[D` to move the cursor back and `\033[K` to delete all the characters to the end of the line.
```go {hl_lines=[1, "12-27"]}
	line, cursorPos := "", 0

	for {
		c, _ := reader.ReadByte()

		// Ctrl+C is pressed
		if c == 3 {
			fmt.Println("Exiting...")
			exit()
		}

		// backspace is pressed
		if c == 127 {
			if cursorPos > 0 {
				fmt.Print("\033[D\033[K")
				line = line[:len(line)-1]
				cursorPos--
			}

			// If cursor reached beginning of line, don't do anything
			continue
		}

		// Any normal character
		fmt.Printf("%c", c)
		line += string(c)
		cursorPos = len(line)
	}
```

Run the program now and see that backspace is working. Also let's discard the typed-in text and show the prompt again when Enter key is pressed.

```go {hl_lines=["1-5"]}
	// the enter key was pressed
	if c == 10 {
		fmt.Println()
		break
	}

	// Any normal character
	fmt.Printf("%c", c)
	line += string(c)
	cursorPos = len(line)
```

Control keys such as Arrow keys, PageUp, PageDown etc. send special 3 byte sequences starting with the byte 27. Let's use the left/right arrow keys to move around the current typed text. We'll discard up/down arrow keys input for now.

```go {hl_lines=["8-26"]}
	// the enter key was pressed
	if c == 10 {
		fmt.Println()
		break
	}

	// Special control key was pressed
	if c == 27 {
		c1, _ := reader.ReadByte()
		if c1 == '[' {
			c2, _ := reader.ReadByte()
			switch c2 {
			case 'C':
				if cursorPos < len(line) {
					fmt.Printf("\033[C")
					cursorPos++
				}
			case 'D':
				if cursorPos > 0 {
					fmt.Printf("\033[D")
					cursorPos--
				}
			}
		}
		continue
	}
```
But we can see that typing in-between characters overwrites the following characters. Let's fix that using some cursor manipulation. The code should be easy to understand.

```go
	// Any normal character
	if cursorPos == len(line) {
		fmt.Printf("%c", c)
		line += string(c)
		cursorPos = len(line)
	} else {
		temp, oldLength := line[cursorPos:], len(line)
		fmt.Printf("\033[K%c%s", c, temp)
		for oldLength != cursorPos {
			fmt.Printf("\033[D")
			oldLength--
		}
		line = line[:cursorPos] + string(c) + temp
		cursorPos++
	}
```

Also pressing backspace in-between characters needs to be fixed
```go
	// backspace was pressed
	if c == 127 {
		if cursorPos > 0 {
			if cursorPos != len(line) {
				temp, oldLength := line[cursorPos:], len(line)
				fmt.Printf("\b\033[K%s", temp)
				for oldLength != cursorPos {
					fmt.Printf("\033[D")
					oldLength--
				}
				line = line[:cursorPos-1] + temp
				cursorPos--
			} else {
				fmt.Print("\b\033[K")
				line = line[:len(line)-1]
				cursorPos--
			}
		}
		continue
	}
```

This concludes Part 1 of this post. Now we have a shell prompt in which we can type commands. In Part 2, we will implement Shell history and start interpreting commands.