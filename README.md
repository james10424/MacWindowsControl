#  Mac Windows Control

Saves, restores window position in Mac

Prerequisite:
Have a `json` file with pre-defined window information, for example:
> You can find window name on the top left corner, next to the Apple logo

- If you know the location and size:
```
[
    {
        "name": "Calendar",
        "x": 2561,
        "y": -478,
        "width": 1078,
        "height": 659
    },
    {
        "name": "Mail",
        "x": 2560,
        "y": 182,
        "width": 1079,
        "height": 692
    },
]
```

- If there are multiple windows for this app:
> `windowIdx` starts from 0
```
[
    {
        "name": "Mail",
        "x": 2560,
        "y": 182,
        "width": 1079,
        "height": 692,
        "windowIdx": 1
    },
]
```

- If you don't know the location and size:
> Just fill in all window name, `windowIdx` and leave other information 0, load this file, then `shift + righ click` to retrieve and fill in the missing info
```
[
    {
        "name": "Calendar",
        "x": 0,
        "y": 0,
        "width": 0,
        "height": 0,
        "windowIdx": 1
    },
    {
        "name": "Mail",
        "x": 0,
        "y": 0,
        "width": 0,
        "height": 0,
        "windowIdx": 1
    },
    {
        "name": "Xcode",
        "x": 0,
        "y": 0,
        "width": 0,
        "height": 0,
        "windowIdx": -1
    }
]
```
> `windowIdx: -1` means the last window

To run:
1. Compile and start the app
1. It will ask you to select a config file
1. To put those windows in the config file back to pre-defined location and size, simply click on the `❖` icon in the status bar
1. To get the current location and size of the windows in the config file, `shift + righ click` on the icon. The info is saved in the memory, but you can decide whether to save it as a file.
1. To load another config file, `right click` on the icon
