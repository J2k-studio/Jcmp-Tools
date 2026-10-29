# jrawser

Jrawser is the browser of the Jaric app: the system WebView (a full web: HTML5, JavaScript, video) in a window of the old programs, with tabs, an address bar that also searches, bookmarks, history, find in page, desktop mode, share, and downloads to `u:/Download`. This tool opens it from the terminal.

## Commands
```
jrawser                      the browser opens
jrawser example.org          a page (https:// is added)
jrawser how to cook rice     a search (duckduckgo, or the page set in ~/.config/jaric/settings: search = https://...?q=)
```
In the window: the keys at the left are back, forward, reload; the right key is the menu (bookmark, bookmarks, history, desktop site, find, share, open in another app, new tab, clear cookies and cache); a long touch on a tab closes it.
Privacy: no account, no sync; a page of the web gets no access to the files of the phone; bookmarks and history are text files in `~/.config/jrawser/`.

## Install
```
jc install jrawser                                                      # with jget
curl -fsSL https://raw.githubusercontent.com/J2k-studio/Jcmp-Tools/main/install.sh | sh -s jrawser     # with curl (no jget needed)
```
Both check the SHA-256 of the file before anything is installed. Needs the Jaric app 0.0.206 or newer.

## A short lesson
Type `jrawser github.com/J2k-studio`, touch the menu key, "Bookmark this page", then "Bookmarks" to find it again. A link to a file (a `.zip`, a `.jc`) is downloaded to `u:/Download`: open the Files window to see it.
License: MPL-2.0.
