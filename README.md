# src/components

This directory contains custom Lazarus / Free Pascal visual components and a Lazarus package used by OvoPlayer, OvoText and others of my applications. The components provide UI widgets and helper classes used across the application (sliders, image/icon helpers, registration unit, etc.).

## License

This components are licensed under a modified LGPL license which allow linking on executables, see [this link](https://wiki.freepascal.org/FPC_modified_LGPL) for details. 


## Contents

- `ovocomponents.lpk` — Lazarus package file containing the components in this folder.
- `registerovocomponents.pas` — Unit that registers the components in the Lazarus component palette.

### Visual / helper components
- `fontimagelist.pas` — A FontImageList component: draw icons from fonts or font-based glyph sets into an image list for use in UI controls.
- `fontimagelisteditor.pas` / `fontimagelisteditor.lfm` — Editor form and Lazarus form file used to edit FontImageList entries inside the IDE.
- `iconrender.pas` — Helper unit to render icons (likely used by OSD, toolbar or lists).
- `imagetrack.pas` — Component for image tracking/display (used for cover art, animated images, or image lists tied to tracks)

### Sliders and skins
- `slider.pas` — Base/custom slider control used by the application.
- `skinnedslider.pas` — Skinned slider control with custom drawing and styling.
- `skinnedslider_icon.lrs` — Resource file used by the skinned slider (contains embedded images/icons used by the component).
- `themedslider.pas` — Themed slider variant that adapts to application theme or style.

### Subdirectories
- `network/` — (directory) network-related components; open that folder for network-specific components and units.

## How to install (Lazarus)

1. Open Lazarus IDE.
2. Open the package file `src/components/ovocomponents.lpk` (Package → Open Package File (.lpk)).
3. Compile and then Install the package. Lazarus may prompt to rebuild the IDE.
4. After installation the components should appear in the component palette and can be dropped onto forms.

## Contributing

Contributions are welcome. Please open issues or pull requests on the main repository. Describe the component change, provide screenshots if it affects UI, and include minimal reproduction steps.
