* Discovery

    By scanning the open ports of the wyze camera, I accidently discovered there is an http server running. This server allows you download any content on the SD card. I assume this is used to download the timelapse video, which is the reason why it requires your phone to be in the same network for doing that.

* Analysis

    So I did some quick analysis on the http server. It's using a software called "boa". The server will allow you download any files in the SD card, as long as you know the path. The SD card is symbolic linked as "/tmp/www/SDPath", where "/tmp/www" is the document root directory of the http service. This means, for example, to download file "alarm/20200403/20200403_10_00_25.jpg", you will need to browse to "http://\<ipaddress\>/SDPath/alarm/20200403/20200403_17_00_25.jpg"

    This will be very useful to access the recordings on SD card. However, requiring knowlege of the file path makes this useless. Luckily, there is something else: There is a CGI script, called "hello.cgi" allowing you to browse "any" directory on the camera. So you need to specify a "name" parameter as the path of the directory, relative to the SD card root. So if I do "http://\<ipaddress\>/cgi-bin/hello.cgi?name=/alarm/20200403/", it will list all the files and sub-directories under that directory.

* Automated SD card content downloading
  
    By combining the "hello.cgi" and the web server, we can build a simple script iterating all the directories and then download all the files. There is really no complexity of this script other than a nice user interface.

* Security concerns
   
    Having a open http server running on the camera can be a security risk. To me the risk is kind of acceptable, because if someone can get into my homenetwork, then there are much bigger issues I need to worry about. Anway, it seems Wyze already noticed this can be a security concern and they are improving it: In older versions I remember this service is always running, but now it only starts when you go to the "view album" page under the timelapse menu from the app. So this serves as some sort of indirect authentication. The server will be shutdown after a certain time to avoid being misused.


