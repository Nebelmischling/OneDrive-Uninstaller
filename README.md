# OneDrive-Uninstaller
A batch script to completely uninstall OneDrive in Windows 10 and 11.

# READ THIS STUFF, FOR REALS BROOO!!!
Download the latest 'Onedrive Uninstaller' batch file and run it as Administrator (right click the file, 'Run as Administrator') to completely remove OneDrive.

Removing OneDrive WILL break access to existing OneDrive accounts and delete locally stored files. It may also break roaming profiles, App Store config, and cloud based Windows settings (like using a Microsoft account to log in). If you don't use that stuff, you're home free (but check anyway).

Either way, BACK UP YOUR STUFF!! Set a restore point or take a drive image if you're unsure.

# What V2.0 does:
- Kills all OneDrive processes first so nothing's locked.
- Scans Startup and removes any OneDrive entries.
- Finds and deletes OneDrive Scheduled Tasks.
- Removes the Active Setup key that reinstalls OneDrive for new users.
- Cleans every user profile, not just yours (including their offline registry).
- Takes ownership of locked files so they actually delete.
- Deletes all known OneDrive files, folders and registry keys for Windows 10 and 11.
- Clears OneDrive environment variables, cached credentials and prefetch files.
- Resets Desktop/Documents/Pictures back to local folders if OneDrive hijacked them.
- Blocks OneDrive from reinstalling (DisableFileSyncNGSC policy).

# Heads up
Run it as Administrator. If you see any 'access denied' messages, reboot and run it once more. That's normal.

Let me know if you find a bug or want any features. Find me on Reddit or something.

Peace out.
