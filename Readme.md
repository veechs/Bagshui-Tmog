# Bagshui-Tmog

Allow [Bagshui](https://github.com/veechs/Bagshui)'s `Transmog()` [rule function](https://github.com/veechs/Bagshui/wiki/Rules) to access Turtle WoW transmog data via [Tmog](https://github.com/Otari98/Tmog).

## Usage
Create a [Category](https://github.com/veechs/Bagshui/wiki/Categories) to accomplish what you want to do using the example rules below for reference.
| Items Matched | Rule |
|:--------------|:-----|
| In your transmog collection. | `Transmog()` |
| Not in your transmog collection. | `Transmog(Eligible) and not Transmog()` |

## Installation

1. Install [Bagshui](https://github.com/veechs/Bagshui).
2. Install [Tmog](https://github.com/Otari98/Tmog).
3. Coninue below to install Bagshui-Tmog.

### Easy mode (recommended)

Use [GitAddonsManager](https://woblight.gitlab.io/overview/gitaddonsmanager/).

### Manual

1. [Download Bagshui-Tmog](https://github.com/veechs/Bagshui-Tmog/archive/refs/heads/main.zip).
2. Extract the zip file.
3. Rename the resulting `Bagshui-Tmog-main` folder to `Bagshui-Tmog`.
4. Move that folder to `[Path\To\WoW]\Interface\Addons`.
5. Ensure the structure is `Interface\Addons\Bagshui-Tmog\Bagshui-Tmog.toc`.  
   <sup>*These are all **wrong**:*  
    × `Bagshui-Tmog-main\Bagshui-Tmog.toc`  
    × `Bagshui-Tmog\Bagshui-Tmog\Bagshui-Tmog.toc`  
	  × `Bagshui-Tmog\Bagshui-Tmog-main\Bagshui-Tmog.toc`
   </sup>

# Credits

Thanks to Otari90 for creating Tmog to handle all the heavy lifting of dealing with the Turtle WoW transmog API.
