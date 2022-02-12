#  Mac Windows Control

Saves, restores window position in Mac

## Running the app
1. Compile and start the app
1. Allow the app to control accessibility features
1. To put those windows in the config file back to pre-defined location and size, left-click on the `❖` icon in the status bar
1. To open up the UI, right-click on the icon.

## UI

### Terminologies
* `Process Name`: The name of the process, can be found on the top-left corner of the screen, next to the Apple logo.
    * Can edit by clicking
* `Window Name`: Thw window name of the process, if you want to lock in a specific window
    * The default is nothing, which means you can get any window
    * Can edit by clicking
* `x`, `y`, `Width`, `Height`: The window property
    * Can be read by performing these steps:
        1. Highlight the row (can highlight multiple)
        1. Hit the `Locate` button
    * Can edit by clicking on the number
* `Index`: The index of the window, in case there are multiple of the same name
    * If `Window Name` is not specified, the index is in the range of all opened windows of `Process Name`
    * If `Window Name` is specified, the index is in the range of all windows of that `Process Name` with the **exact same name** in the window title. For example, there are 2 windows opened for `Finder`, `Downloads` and `Applications`, then specifying `Downloads` as the `Window Name` and 1 as the `Index` is invalid.
    * Can be edited by clicking
* `Status`: Indiates whether the window listed encountered error or not
    * Green: This window configuration can be found and has been linked, no problem so far
    * Red: This window has not been found (or first started), or there was an error locating/setting this window. Hover over the red dot to see the error message

## Buttons
* `Add`: Add a window config and begin editing the `Process Name`
* `Remove`: Remove the highlighted rows
* `Save`: Save the current config to a `json` file. If the file is successfully saved, the program will launch with the last saved file as the config.
* `Open`: Open a `json` config file, if successfully read, replace the current config with it and the program will launch with the last opened file as the config.
* `Locate`: Locate the window location and size of highlighted rows and updates them in the UI. If there was an error locating them, the `Status` column will turn red and error message will be in the tooltip of the red dot (hover). If they are located (green status), the updated information will be stored and used in the next `Apply` 
* `Apply`: Apply the selected rows to their respective window. If there was an error applying, the `Status` column will turn red and error message can be found hovering the red dot

