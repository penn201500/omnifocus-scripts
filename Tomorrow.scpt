(*
	# DESCRIPTION #

	This script takes the currently selected actions or projects and sets them to be due tomorrow. Works on tasks past due, currently due, or due in the future.
	
	Logic applied to each item:
		- If no original due date, sets due to tomorrow at the set time
		- If original due date, sets due to tomorrow at the *original* due time
		- If original due date AND start date, advances start date by same # of days as due date (this is to respect parameters of repeating actions)
		- Ignores start date if there's no due date already assigned to a task
	
	
	# LICENSE #
	
	Copyright © 2009-2010 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	

	# CHANGE HISTORY #

	version 0.2c (2010-06-22)
	-	Actual fix for autosave

	version 0.2b (2010-06-21)
	-	Encapsulated autosave in "try" statements in case this fails

	version 0.2 (2010-06-15)
	-	Added performance optimization (thanks to Curt Clifton)
	-	Fixed Growl code (broke with Snow Leopard)
	-	Switched to MIT license (simpler, less restrictive)

	version 0.1: Initial release. Based on my Defer script, which incorporates bug fixes from Curt Clifton. Also uses method that doesn't call Growl directly. This code should be friendly for machines that don't have Growl installed. In my testing, I found that GrowlHelperApp crashes on nearly 10% of AppleScript calls, so the script checks for GrowlHelperApp and launches it if not running. (Thanks to Nanovivid from forums.cocoaforge.com/viewtopic.php?p=32584 and Macfaninpdx from forums.macrumors.com/showthread.php?t=423718 for the information needed to get this working

	# INSTALLATION #

	-	Copy to ~/Library/Scripts/Applications/Omnifocus
 	-	If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus

	# KNOWN BUGS #
	-	When the script is invoked from the OmniFocus toolbar and canceled, OmniFocus returns an error. This issue does not occur when invoked from the script menu, a Quicksilver trigger, etc.
		
*)

property showAlert : false --if true, will display success/failure alerts
property useGrowl : true --if true, will use Growl for success/failure alerts
--property defaultSnooze : 1 --number of days to defer by default
property alertItemNum : ""
property alertDayNum : ""
property growlAppName : "Dan's Scripts"
property allNotifications : {"General", "Error"}
property enabledNotifications : {"General", "Error"}
property iconApplication : "OmniFocus.app"
property dueTime : 17 --Time of due for items not previously assigned a due time (24 hr clock)
--property homeDueTime : 20 --If item is in "Home" category, time of due

tell application "OmniFocus"
	tell front document
		tell (first document window whose index is 1)
			set theSelectedItems to selected trees of content
			set numItems to (count items of theSelectedItems)
			if numItems is 0 then
				set alertName to "Error"
				set alertTitle to "Script failure"
				set alertText to "No valid task(s) selected"
				my notify(alertName, alertTitle, alertText)
				return
			end if
			set currDate to (current date) - (time of (current date))
			set currDate to currDate + 86400
			set selectNum to numItems
			set successTot to 0
			set autosave to false
			repeat while selectNum > 0
				set selectedItem to value of item selectNum of theSelectedItems
				set succeeded to my tomorrow(selectedItem, currDate)
				if succeeded then set successTot to successTot + 1
				set selectNum to selectNum - 1
			end repeat
			set autosave to true
			set alertName to "General"
			set alertTitle to "Script complete"
			if successTot > 1 then set alertItemNum to "s"
			set alertText to successTot & " item" & alertItemNum & " now due tomorrow." as string
		end tell
	end tell
	my notify(alertName, alertTitle, alertText)
end tell

on tomorrow(selectedItem, currDate)
	set success to false
	tell application "OmniFocus"
		try
			set theDueDate to due date of selectedItem
			if (theDueDate is not missing value) then
				set theDueStart to theDueDate - (time of theDueDate)
				set theDelta to (currDate - theDueStart) / 86400
				set newDue to (theDueDate + (theDelta * days))
				set due date of selectedItem to newDue
				set theStartDate to start date of selectedItem
				if (theStartDate is not missing value) then
					set newStart to (theStartDate + (theDelta * days))
					set start date of selectedItem to newStart
				end if
				set success to true
			else
				set due date of selectedItem to (currDate + (dueTime * hours))
				set success to true
			end if
		end try
	end tell
	return {success}
end tomorrow


on notify(alertName, alertTitle, alertText)
	if showAlert is false then
		return
	else if useGrowl is true then
		--check to make sure Growl is running
		tell application "System Events" to set GrowlRunning to ((application processes whose (name is equal to "GrowlHelperApp")) count)
		if GrowlRunning = 0 then
			--try to activate Growl
			try
				do shell script "/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app/Contents/MacOS/GrowlHelperApp > /dev/null 2>&1 &"
				do shell script "~/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app/Contents/MacOS/GrowlHelperApp > /dev/null 2>&1 &"
			end try
			delay 0.2
			tell application "System Events" to set GrowlRunning to ((application processes whose (name is equal to "GrowlHelperApp")) count)
		end if
		--notify
		if GrowlRunning ≥ 1 then
			try
				tell application "GrowlHelperApp"
					register as application growlAppName all notifications allNotifications default notifications allNotifications icon of application iconApplication
					notify with name alertName title alertTitle application name growlAppName description alertText
				end tell
			end try
		else
			set alertText to alertText & " 
 
p.s. Don't worry—the Growl notification failed but the script was successful."
			display dialog alertText with icon 1
		end if
	else
		display dialog alertText with icon 1
	end if
end notify