+++
title = "HLS streaming using Node.js"
description = "Write an HLS streaming server in Node.js"
tags = [
    "node",
    "javascript"
]
date = "2019-05-15"
categories = [
    "Node.js",
]
draft = true
+++

The very basic and beginner level way is to use a client-side video client or a `<video>` tag available in HTML5 and give it a src attribute linking to the video file hosted on the cloud.

However, this method is definitely not how most of the videos are available on the internet - partly because it requires the client to first fetch the entire video and then play it. Imagine how this would play out in case of longer, heavier videos. Another reason this approach is avoided is because anyone can download your videos by simply going to the source URL.

The solution to this problem is to send your video to the client in smaller packets and deliver more as the client plays through the video. This is how most of the video streaming services such as YouTube, Netflix, Amazon Prime, Hulu, etc deliver their video content to their users.

Ok so let’s create a very basic streaming server in Golang.