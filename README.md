Growl Reeder
============

This is a tiny plugin to enable Growl desktop notification in awesome [Reeder.app for Mac](http://reederapp.com/).
I've tested this plugin with only current Reeder Version 1.0 Draft 2 which is beta version.

Are you looking for the Reeder.app for Mac? You can grab the link from [their tweets](http://twitter.com/reederapp).

How to use this?
----------------

1.  Goto [my blog article](http://niw.at/articles/2010/12/05/growl-plugin-for-reeder-for-mac/) to gownload the binary of GrowlReeder.

1.	Install [SIMBL](http://www.culater.net/software/SIMBL/SIMBL.php) prior to use this plugin,
	if you didn't install it yet.

1.	Open ``~/Library/Application Support/SIMBL/Plugins`` folder.
	If it doesn't exists, create it.

1.	Copy or symlink ``GrowlReeder.bundle`` into that folder.

1.  Restart Reeder.app.


How to build this plugin?
-------------------------

Open this project with Xcode then build. All is in this project, includes ``Growl.framework``.
While building, the script may create a symlink or copy the bundle build into SIMBL ``Plugins`` folder.
If you want to debug this, just adding a new custom executable of ``Reeder.app`` then click Build and Debug.
