+++
title = "HLS streaming using Node.js"
description = "Write an HLS streaming server in Node.js"
tags = [
    "node",
    "javascript"
]
date = "2019-03-03"
categories = [
    "Node.js",
]
draft = true
+++

Let's say, you want to stream videos over the internet. The most basic way is to use a video client like VLC or a `<video>` tag available in HTML5 and give it a `src` attribute linking to the video file hosted somewhere in the cloud.

Let's see how we can go about implementing a simple express API to achieve this. Since the http `request` and `response` objects are streams, we can simply create a `readStream` from the video file and pipe it to the `response` object. Also have a file named __sample.mp4__ in the same directory.

```javascript
const express = require("express");
const fs = require("fs");
const app = express();

app.get('/video', (request, response) => {
    const filePath = 'sample.mp4';
    const { size } = fs.statSync(filePath);

    response.writeHead(200, {
        'Content-Length': size,
        'Content-Type': 'video/mp4'
    });
    fs.createReadStream(filePath).pipe(response);
});

app.listen(8000, () => console.log(`Server listening on port 8000..`));
```

The client html is just a simple `<video>` tag.

```html
<video id="videoPlayer" controls>
    <source src="http://localhost:8000/video" type="video/mp4">
</video>
```

The video should play fine. But if you try to seek this video past the buffered section, you'll notice that it doesn't work. When seeked, HTML5 videos typically send an [HTTP range](https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests) request to the video source url to recieve unbuffered chunks of video.

An HTTP range request is plain GET request which contains a request header named `Range` of the format `Range: bytes=chunkStart-`. The server should respond with a _HTTP 206 Partial Content_ and the following headers.

```
'Content-Range': 'bytes chunkStart-chunkEnd/chunkSize'
'Accept-Ranges': 'bytes'
'Content-Length': chunkSize
```

To make our Express server capable of handling range requests, we'll parse the request's `Range` header and respond with only the requested bytes.

```javascript {hl_lines=["4-21"]}
app.get('/video', function(request, response) {
    const filePath = 'sample.mp4';
    const fileSize = fs.statSync(filePath).size;
    const { range } = request.headers;

    // This is a range request
    if (range) {
        const parts = range.replace(/bytes=/, "").split("-");
        const start = parseInt(parts[0]);
        const end = parts[1] ? parseInt(parts[1]): fileSize-1;
        const chunksize = (end-start)+1;
        res.writeHead(206, {
            'Content-Range': `bytes ${start}-${end}/${fileSize}`,
            'Accept-Ranges': 'bytes',
            'Content-Length': chunksize,
            'Content-Type': 'video/mp4',
        });

        // Create a read stream from only start to end bytes
        const chunk = fs.createReadStream(filePath, { start, end });
        chunk.pipe(response);
    } 
    // This is a non-range request
    else {
        response.writeHead(200, {
            'Content-Length': fileSize,
            'Content-Type': 'video/mp4',
        });
        fs.createReadStream(filePath).pipe(response);
    }
});
```
Now when you run the server, you can see that seeks are working properly. So are we done? Not yet. While this method works, this is not how video streaming services such as YouTube, Netflix, Amazon Prime etc. deliver their video content to their users. Imagine how this would play out in case of very high bitrate videos like 4K. A lot of bytes would have to be downloaded to play even a second of the video.

Enter [HTTP Live Streaming](https://en.wikipedia.org/wiki/HTTP_Live_Streaming), also known as HLS.

HLS was first developed by Apple in order to stream video and audio over HTTP from any basic web server without spending a lot of time/ effort/ money on a heavyweight streaming server. This approach was heavily used across all Apple devices and later it became the common standard for streaming videos across the Internet.

Another similar format is DASH, which is an acronym for Dynamic Adaptive Streaming over HTTP.

The main difference between HLS and DASH is the video codec. HLS requires the videos to be encoded with H264 codecs. DASH is flexible in terms of covering other codecs - which is why DASH is more likely to become the universal standard.

We are going to work with HLS in this example, for ease. Using the [FFMPEG](https://ffmpeg.org/) library, you can convert an MP4 file into HLS manifest and data files. This might take a while depending on your system specifications.


```
ffmpeg -i sample.mp4 -profile:v baseline -level 3.0 -s 640x360 -start_number 0 -hls_time 10 -hls_list_size 0 -f hls index.m3u8
```

The hls_time flag defines the duration of each segment. Here it’s set to 10 which means that if the video is 100 seconds long, FFMEG will split it into 10 .ts segments which will be 10 seconds long.

The output files will include 10 .ts segment files and 1 index.m3u8 manifest file with details about which .ts file includes which segment of the video.

This is what the index.m3u8 file looks like

```
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:12
#EXT-X-MEDIA-SEQUENCE:0
#EXTINF:12.320000,
index0.ts
#EXTINF:8.720000,
index1.ts
#EXTINF:12.280000,
index2.ts
```
