Chat Translator
===============
<pre>
Chat Translator uses <a href="https://github.com/LibreTranslate/LibreTranslate">LibreTranslate</a> to translate chat messages in Minetest.
In order to use this mod, LibreTranslate will need to be installed and running on your 
Minetest server. LibreTranslate can be installed and started with a single command:
"docker run -ti --rm -p 5000:5000 libretranslate/libretranslate"
Alternative installation methods can be found here: <a href="https://github.com/LibreTranslate/LibreTranslate/blob/main/README.md#install-and-run">LibreTranslate Installation</a>

In order to run Chat Translator, you will also need to add the mod to your
trusted mods list. To do so, click on the 'Settings' tab in the main menu. 
Click the 'All Settings' button and in the search bar, enter 'trusted'. 
Click the 'Edit' button and add 'chat_translator' to the list.

Once everything is installed and running, Chat Translator will attempt to translate all chat 
messages sent on your server. The language in which each player receives messages is 
determined by the language selected in the Minetest settings menu.

<img src="https://i.imgur.com/qlRfMM9.png" alt="Chat Translator" width="600" height="338"></br>
The player in the upper right corner sent a message in English. On the upper left, 
the message is translated to Spanish. On the lower left, the message is received 
in German and on the bottom right, the message is displayed in French.
</pre>
