# Vitrea OS downloads

## T2 Mac edition (2018–2020 Intel Macs with the T2 chip, incl. the 2019 Mac Pro)

GitHub limits files to 2 GB, so the 3.3 GB ISO is in two parts. Download **both**
(click each file, then the download button):

- `vitrea-os-t2-1.0-2026.11.20-x86_64.iso.part1`
- `vitrea-os-t2-1.0-2026.11.20-x86_64.iso.part2`

Put them in the same folder and join them. On a Mac, open Terminal in that folder:

```bash
cat vitrea-os-t2-1.0-2026.11.20-x86_64.iso.part1 vitrea-os-t2-1.0-2026.11.20-x86_64.iso.part2 > vitrea-os-t2-1.0-2026.11.20-x86_64.iso
shasum -a 256 vitrea-os-t2-1.0-2026.11.20-x86_64.iso
```

On Windows (Command Prompt):

```
copy /b vitrea-os-t2-1.0-2026.11.20-x86_64.iso.part1 + vitrea-os-t2-1.0-2026.11.20-x86_64.iso.part2 vitrea-os-t2-1.0-2026.11.20-x86_64.iso
certutil -hashfile vitrea-os-t2-1.0-2026.11.20-x86_64.iso SHA256
```

The checksum must be:

```
34432d080750670e03a31e526e362ef7a5e0b4b8073f00b7d9d7b9bf06972916
```

Then write the `.iso` to a USB stick (KDE ISO Image Writer, balenaEtcher or `dd`) and follow
the **T2 Macs** section of the README on the `main` branch.
