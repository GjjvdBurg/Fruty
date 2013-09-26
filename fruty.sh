#!/usr/bin/env bash

fruty_version="0.1"

# Definitions for colour output
res='\033[1m\033[0m'
warn() { echo -e "\e[34m$*${res}"; }
log() { echo -e "\e[32m$*${res}"; }
err() { echo -e "\e[31m$*${res}"; exit 1; }

log "Checking dependencies..."
hash fontforge 2>&- || err "Please install fontforge to use this script."

log "Creating temp directory..."
mkdir /tmp/frutigertemp
cd /tmp/frutigertemp

log "Getting CartoGothic Std font..."
wget http://www.fontsite.com/freefonts/CartoGothicStd.zip || err "Failed to download CartoGothicStd.zip"

log "Unpacking..."
unzip CartoGothicStd.zip || err "Failed to extract CartoGothic Std."

log "Creating user font directory..."
mkdir -p ~/.fonts/cartogothic_std/

log "Copying font files..."
cp /tmp/frutigertemp/CartoGothicStd/*.otf ~/.fonts/cartogothic_std/

log "Updating user font cache..."
fc-cache -f -v || err "Failed to update font cache..."

log "Renaming CartoGothic font files..."
cp CartoGothicStd/CartoGothicStd-Book.otf pfrr8a.otf
cp CartoGothicStd/CartoGothicStd-Bold.otf pfrb8a.otf
cp CartoGothicStd/CartoGothicStd-Italic.otf pfrri8a.otf
cp CartoGothicStd/CartoGothicStd-BoldItalic.otf pfrbi8a.otf

log "Creating fontforge script..."
cat > otf2pfb.sh << EndOfCat
#!/usr/bin/fontforge
# Quick and dirty hack: converts a font to Postscript Type one (.pfb)
i = 1

while ( i < \$argc )
	Print("Opening: " + \$argv[i]);
	if(\$argv[i]:e != "otf")
		Print("Skipping ... Expecting an OpenType font [.otf]")
	else
		Open(\$argv[i])
		Print("Saving: " + \$argv[i]:r+".pfb");
		SetFontOrder(3)
		SelectAll()
		Simplify(128+32+8,1.5)
		ScaleToEm(1000)
		DontAutoHint()
		Generate(\$argv[i]:r+".pfb")
	endif
	i = i + 1
endloop
EndOfCat

chmod +x otf2pfb.sh
./otf2pfb.sh pf*.otf

log "Getting pfr.zip..."
wget http://mirrors.ctan.org/fonts/psfonts/w-a-schmidt/pfr.zip || err "Failed to download pfr.zip."

log "Creating ~/texmf (if necessary)..."
mkdir -p ~/texmf

log "Unzipping pfr.zip..."
unzip pfr.zip -d ~/texmf/ || err "Failed to unpack pfr.zip."

log "Moving pfr fonts..."
mkdir -p ~/texmf/fonts/type1/adobe/frutiger/
mv pfr*.pfb ~/texmf/fonts/type1/adobe/frutiger/
mkdir -p ~/texmf/fonts/afm/adobe/frutiger/
mv pfr*.afm ~/texmf/fonts/afm/adobe/frutiger/

log "Updating local TeX font map..."
texhash || err "Failed to call texhash."
updmap --enable Map pfr.map || err "Failed to update font map."

log "Creating test document..."
cat > fruttest.tex << EndOfCat
\\documentclass{article}
\\usepackage[T1]{fontenc}
\\usepackage{frutiger}
\\begin{document}
\\sffamily
Test 1234
\\end{document}
EndOfCat

log "Building test document..."
pdflatex fruttest.tex || err "Failed to build document."

if [ -f fruttest.pdf ]
then
	if hash zathura 2>/dev/null; then
		zathura fruttest.pdf
	elif hash evince 2>/dev/null; then
		evince fruttest.pdf
	elif hash okular 2>/dev/null; then
		okular fruttest.pdf
	elif hash acroread 2>/dev/null; then
		acroread fruttest.pdf
	else
		err "No known pdf reader found on system."
	fi
fi

log "Cleaning up..."
rm -r /tmp/frutigertemp

warn "Warning: The font does not show up when compiling through the .dvi toolchain."
log "Done."
