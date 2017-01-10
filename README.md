#TOF File Cleaner
(togfilecleaner)
##Description
This plugin allows users to create as many setups as desired for managing servers files. When each setup is run, the plugin searches in the path set and determines if each file within the path matches the criteria set by the user in the .txt file. The .txt file can contain as few or as many setups as desired. For matching files, the specified action is then taken (either delete, move, or copy...there are plans for more in the future).



##Installation
* Put togfilecleaner.smx in the following folder: /addons/sourcemod/plugins/
* Put togfilecleaner.txt in the following folder: /addons/sourcemod/configs/



##CVars
* **tfc_log** - Enables logging of files that actions are taken on.




##Default Configuration File
<details>
<summary>Click to Open Spoiler</summary>
<p>
<pre><code>
"Setups"
{
	"SM Directory Setups"
	{
		"SM Main Logs"
		{
			"enabled"		"1"
			"filepath"		"logs"
			"days"			"3"
			"string"		"L"
			"case"			"1"
			"extension"		".log"
			"exclude"		"Chat"
		}
		"SM Error Logs"
		{
			"enabled"		"1"
			"filepath"		"logs"
			"days"			"10"
			"string"		"error"
			"case"			"0"
			"extension"		".log"
			"exclude"		"clean"
		}
		"Chat Logger"
		{
			"enabled"		"1"
			"filepath"		"logs/chatlogger"
			"days"			"5"
			"string"		"chatlogs_"
			"case"			"0"
			"extension"		".log"
			"exclude"		"clean"
		}
		"TOG Store Logs"
		{
			"enabled"		"1"
			"filepath"		"logs/togstore"
			"days"			"20"
			"string"		"togstore"
			"case"			"0"
			"extension"		".log"
			"exclude"		"save"
		}
	}

	"Root Directory Setups"
	{
		"Server Logs"
		{
			"enabled"		"1"
			"filepath"		"logs"
			"days"			"2"
			"string"		"l"
			"case"			"0"
			"extension"		".log"
			"exclude"		"none"
		}
		"Old Demos Delete"
		{
			"enabled"		"1"
			"filepath"		"/demos"
			"days"			"3"
			"string"		"auto-"
			"case"			"1"
			"extension"		"any"
			"exclude"		"none"
		}
		"Old Demos Move"
		{
			"enabled"		"1"
			"filepath"		""
			"days"			"0.03"
			"string"		"auto-"
			"case"			"1"
			"extension"		"any"
			"exclude"		"none"
			"action"		"move"
			"newpath"		"/demos"
		}
	}
}
</code></pre>
</p>
</details>




##Explanation of Configuration File
<details>
<summary>Click to Open Spoiler</summary>
<p>
<pre><code>
"Setups"												//DO NOT CHANGE THIS LINE.
{														//DO NOT REMOVE THIS BRACKET.
	"SM Directory Setups"								//DO NOT CHANGE THIS LINE. All subkeys of this section are setups withing the sourcemod directory (addons/sourcemod/ for most).
	{													//DO NOT REMOVE THIS BRACKET.
		"SM Main Logs"									//Rename/change this however you see fit. This would be the first setup for files to clean/delete.
		{
			"enabled"		"1"							//1 = enabled. Set to 0 to disable your setup without deleting it. For EVERY key-value, if it is omitted, the default is assumed. Default: 0
			"filepath"		"logs"						//Path to the folder you want to search in. Path assumes sourcemod directory, so this would look in addons/sourcemod/logs. Default: logs
			"days"			"3"							//Number of days old at which point the file is applied if all other filters pass. This is a float, so it can be decimals (e.g. 3.5 days). Default: 3.0
			"string"		"L"							//What text should the correct files contain in the filename. Default: "none"
			"case"			"1"							//Set to 1 to make the string search case sensitive. Set to 0 to make it case insensitive. In this case, files must have a capitol L to not be ignored. Default: 1
			"extension"		".log"						//What file extensions are the files you wish to delete? Technically, this is just searching for additional text within the filename, so if two strings are needed to customize your setup, you could use this as such. Default: "any"
			"exclude"		"Chat"						//Ignore the file if it contains this text.	Default: ""
			"action"		"delete"					//Action to take with matches. Options are "delete", "move" (see below), and "copy". Default: "delete"
		}
		"SM Error Logs"									//This is your second setup for files to delete.
		{
			"enabled"		"1"
			"filepath"		"logs"
			"days"			"10"
			"string"		"error"
			"case"			"0"							//This is set to case insensitive.
			"extension"		".log"
			"exclude"		"clean"
		}
		"Chat Logger"
		{
			"enabled"		"1"
			"filepath"		"logs/chatlogger"
			"days"			"5"
			"string"		"chatlogs_"
			"case"			"0"
			"extension"		".log"
			"exclude"		"clean"
		}
		"TOG Store Logs"								//This setup has been disabled, so it will not be run.
		{
			"enabled"		"1"
			"filepath"		"logs/togstore"
			"days"			"20"
			"string"		"togstore"
			"case"			"0"
			"extension"		".log"
			"exclude"		"save"
		}
	}													//DO NOT REMOVE THIS BRACKET.

	"Root Directory Setups"								//DO NOT CHANGE THIS LINE. All subkeys of this section are setups withing the root directory (cstrike/ for most).
	{													//DO NOT REMOVE THIS BRACKET.
		"Server Logs"									//First setup in the root directory.
		{
			"enabled"		"1"
			"filepath"		"logs"						//Search in the main server logs directory.
			"days"			"2"
			"string"		"l"							//since all files start with a lowercase L in the logs folder, might as well search for that.
			"case"			"0"
			"extension"		".log"
			"exclude"		"none"
		}
		"Old Demos Move"								//this setup moves demo files into a subfolder
		{
			"enabled"		"1"
			"filepath"		""							//This is searching in the root directory
			"days"			"0.03"						//give it just enough time to finish the demo
			"string"		"auto-"
			"case"			"1"
			"extension"		"any"						//this accepts any file extension. In this case, it could be .dem or .zip
			"exclude"		"none"
			"action"		"move"						//action is to move - which requires the key-value below to specify where to
			"newpath"		"/demos"					//new folder to move the file to. Use a similar setup for the "copy" action
		}
		"Old Demos Delete"								//this setup will delete the old demos inside the subfolder
		{
			"enabled"		"1"
			"filepath"		"/demos"					//files inside root_path/demos/
			"days"			"3"
			"string"		"auto-"
			"case"			"1"
			"extension"		"any"
			"exclude"		"none"
		}
	}													//DO NOT REMOVE THIS BRACKET.
}														//DO NOT REMOVE THIS BRACKET.
</code></pre>
</p>
</details>




##Changelog:
<details>
<summary>Click to Open Changelog</summary>
<p>

<b>v4.2 (8/08/15)</b>
<li>Code updated.</li>
<li>Changed debug mode to be upon compile only.</li>

<b>v4.1</b>
<li>Code updates.</li>

<b>v4.0</b>
<li>Started Change log.</li>
<li>Coded in ability to move stuff, made days a float instead of an integer, gave option to accept "any" file extension</li>

<b>v3.0 (05/28/14)</b>
<li>Added root directory support</li>

<b>v2.2 (03/02/14)</b>
<li>Hooked cvar changes</li>
<li>converted to AutoExecConfig</li>
<li>changed name of version cvar to one not being used by another plugin</li>

<b>v2.0 (03/02/14)</b>
<li>Fixed debug outputting certain lines even if debug isnt enabled.</li>

<b>v1.0 (02/26/14)</b>
<li>Initial release.</li>

</p>
</details>

##Disclaimer
Use this plugin at your own risk! It has been thoroughly tested. However, I am not responsible for any deleted files, etc. on your server from this plugin.

That said, it works great! Just make sure your setup doesnt apply to files you dont want it to. For example, in the default .txt file, if you accidentally set the first setup to case insensitive, it would delete any file in your logs folder with an "L" in it, having the extension ".log", excluding the word chat, and older than 3 days since its last edit. With case sensitive, it would need to be a capitol L in the file name (which most files would not have, and those that do can be filtered out using the "exclude" string).
