#!/usr/bin/env bash

LISTEN=$1

function iso_date() { date --iso-8601=seconds; }

yes | sudo apt install dnsmasq privoxy

sudo cp /etc/dnsmasq.conf{,.orig-$(iso_date)}
sudo cp /etc/privoxy/config{,.orig-$(iso_date)}
sudo cp /etc/privoxy/user.action{,.orig-$(iso_date)}

curl -s http://sbc.io/hosts/alternates/fakenews-gambling-porn-social/hosts | sudo tee /etc/dns-blocklist

echo "listen-address=${LISTEN}
addn-hosts=/etc/dns-blocklist
bogus-priv
cache-size=2000
domain-needed
no-poll
rebind-localhost-ok
stop-dns-rebind
" | sudo tee /etc/dnsmasq.conf

sudo systemctl restart dnsmasq.service; systemctl status dnsmasq.service

echo "forward-socks5 / 10.64.0.1:1080
listen-address 127.0.0.1:8118
toggle 1
confdir /etc/privoxy
actionsfile default.action
actionsfile match-all.action
actionsfile user.action
filterfile default.filter
filterfile user.filter
logdir /var/log/privoxy
logfile logfile
accept-intercepted-requests 1
allow-cgi-request-crunching 0
enable-remote-http-toggle  0
enable-remote-toggle  0
enable-edit-actions 0
enforce-blocks 0
forwarded-connect-retries 0
split-large-forms 0
tolerate-pipelining 1
default-server-timeout 10
keep-alive-timeout 10
socket-timeout 10
buffer-limit 8192
debug     1 # Log the destination for each request Privoxy let through. See also debug 1024.
#debug     2 # show each connection status
#debug     4 # show I/O status
#debug     8 # show header parsing
#debug    16 # log all data written to the network
#debug    32 # debug force feature
#debug    64 # debug regular expression filters
#debug   128 # debug redirects
#debug   256 # debug GIF de-animation
#debug   512 # Common Log Format
debug  1024 # Log the destination for requests Privoxy didn't let through, and the reason why.
#debug  2048 # CGI user interface
debug  4096 # Startup banner and warnings.
debug  8192 # Non-fatal errors
#debug 32768 # log all data read from the network
#debug 65536 # Log the applying actions
" | sudo tee /etc/privoxy/config

echo "
{{ alias }}
+crunch-all-cookies = +crunch-incoming-cookies +crunch-outgoing-cookies
-crunch-all-cookies = -crunch-incoming-cookies -crunch-outgoing-cookies
allow-all-cookies   = -crunch-all-cookies -session-cookies-only -filter{content-cookies}
allow-popups        = -filter{all-popups} -filter{unsolicited-popups}
+block-as-image     = +block{Blocked image request.} +handle-as-image
-block-as-image     = -block
fragile             = -block -crunch-all-cookies -filter -fast-redirects -hide-referer -prevent-compression
{ fragile }
connectivitycheck.gstatic.com/generate_204
www.google.com/gen_204
.netflix.com
.nflxext.com
.nflximg.net
.nflxso.net
.nflxvideo.net
.ubuntu.com
{ +block{html} }
/(.*/)adhandler/
/(.*/)partnerads.*.js
/(aff|adx|scrollad).php
/.*adEvents.*
/.*adimage*/*
/.*ads.js
/.*ads/.*
/.*adserver/*
/.*adtech.*
/.*advert.js.*
/.*advtcontent*/*
/.*affiliate/
/.*analytics.js.*
/.*banner*/*
/.*email=.*
/.*facebook.*
/.*fb.js.*
/.*linkedin.*
/.*php?stats.*
/.*rate.php
/.*shareBar.js
/.*smartads.*
/.*sponsor*/*
/.*track/ping.*
/.*tracking.*.js.*
/.adserv/
/?wordfence_logHuman.*
/FloatingAd.*.js
/ad-loader.js.*
/ad.html
/adGallery.html
/adReload.html
/ad_index_.*
/adheader.*
/adhtml/.*
/adplayer/*
/adtest/*
/adunit.php.*
/advert*/*
/affiliate.js
/ajax/ligatus/*
/analytics/
/banner*.*
/beacon.*
/cms_media/module_adbanner/
/cnt.php.*
/connect.ashx.*
/displayads/
/extjs/smartad.*\.js
/gather.asp.*
/gfx/layer/*
/gujAd/
/log/webtracker
/metriweb.*
/track.*
/urldata.act.*
/vtrack/
ad.
adimg.
admonkey.
ads.
ads.*.co.*/
ads.*.com/
ads2.
adserver.
analytics.*.
emailtrk.*
log.pinterest.com
pixel.*
{ +block{image} +handle-as-image }
/.*1x1.*
/.*beacon.*
/.*buttons.js
/.*facebook.*
/.*fb-icon.*
/.*follow_us.*
/.*images/social.*
/.*linkedin.*
/.*loading.gif
/.*measure.gif
/.*myspace.*
/.*share-buttons.*
/.*share-this.*
/.*static/button.*
/.*tracking-pixel.*
/adv_banner_.*
/assets/social-.*
/banner.php
/btn_ad_.*
/cleardot.gif
/followus-buttons.*
/iframe/ad/.*
/iframe/ads/.*
/image/ad/.*
/images/ad/.*
/images/ads.*
/images/ads/.*
/images/adv.*
/images/banners/
/images/sponsored/.*
/images_ad/.*
/img.ads.*
/img/ad-.*
/img/ad_.*
/img/social.*
/imgad_.*
/socialicons.*
{+set-image-blocker{http://10.8.1.1/}}
/.*.[jpg|jpeg|gif|png|tif|tiff]$
{ +redirect{s@google.com/amp/s/@@} }
google.com/amp/s/.*
{ +redirect{s@http://@https://@} }
.0x0.st
.4are.com
.abc.net.au
.accuweather.com
.adobe.com
.ae.com
.aexp-static.com
.aftership.com
.akamaihd.net
.alternet.org
.amazonaws.com
.amazon.com
.amd.com
.americanexpress.com
.amsecusa.com
.android.com
.annualcreditreport.com
.answers.com
.apache.org
.appimage.org
.apple.com
.archive.is
.archive.org
.archlinux.org
.arduino.cc
.arstechnica.com
.askubuntu.com
.asus.com
.auspost.com.au
.auth0.com
.authorize.net
.awesomeopensource.com
.awsstatic.com
.azurestandard.com
.bankofamerica.com
.bbc.com
.bbc.co.uk
.bing.com
.bitbucket.org
.bitchute.com
.bit.ly
.blogblog.com
.blogger.com
.bloglovin.com
.blogspot.com
.bootc.net
.bootstrapcdn.com
.boum.org
.box.net
.britishcouncil.org
.byexamples.com
.ca.gov
.canadapost.ca
.cbc.ca
.cbsnews.com
.ccc.de
.cdc.gov
.cdninstagram.com
.cdnme.se
cdn.openbsd.org
.cdnst.net
.chase.com
.chromium.org
.chrono24.com
.cia.gov
.cisco.com
.cloudflare.com
.cloudfront.net
.cnbc.com
.cnet.com
.cnn.com
.cnn.io
.colorado.gov
.colostate.edu
.comcast.net
.congress.gov
.coreboot.org
.cpb.gov
.craigslist.org
.creativecommons.org
.crucial.com
.cryptographyengineering.com
.cryptomuseum.com
.cs.cornell.edu
cvsweb.openbsd.org
.dailycaller.com
.db.tt
.dd-wrt.com
.debian-administration.org
.debianforum.de
.debian.net
.definitions.net
.delta.com
.dhs.gov
docs.google.com
drive.google.com
.dropboxatwork.com
.dropbox.com
.dropboxteam.com
.duckduckgo.com
.ebay.com
.ebaystatic.com
.economist.com
.edgekey.net
.editmysite.com
.edx.org
.eff.org
.emacswiki.org
.eso.org
.etsy.com
.etsystatic.com
.export.gov
.fastly.com
.fastly.net
.fbi.gov
.fbinaa.org
.fda.gov
.fedex.com
.ffmpeg.org
.fidelity.com
.finviz.com
.flicker.com
.flickr.com
.flickr.net
.foreignpolicy.com
.ftc.gov
ftp.openbsd.org
.generac.com
.gentoo.org
.gfycat.com
.ggpht.com
.gimp.org
.giphy.com
.githubapp.com
.githubassets.com
.github.com
.github.io
.githubusercontent.com
.gitlab.com
.gitlab.io
.gizmodo.com
.gmail.com
.gnu.org
.gnupg.org
.godoc.org
.gog.com
.gog-statics.com
.golang.com
.golang.org
.goo.gl
.googleapis.com
.googleblog.com
.google.ca
.googlecode.com
.google.com
.google.co.uk
.google.de
.googlemail.com
.google.net
.googlesource.com
.googleusercontent.com
.googlevideo.com
.governmentattic.org
.gravatar.com
.gstatic.com
.gvt1.com
.gvt2.com
.gvt3.com
.haxx.se
.hbr.org
.homedepot.com
.homefinity.com
.house.gov
.houzz.com
.hulu.com
.iana.org
.ibm.com
.icanhazip.com
.icann.org
.ietf.org
.images-amazon.com
.imageshack.com
.imageshack.us
.imdb.com
.imgur.com
.independent.ie
.indiegogo.com
.instagram.com
.intel.com
.intuit.com
.irs.gov
.isc.org
.ixquick.com
.jhu.edu
.jobvite.com
.jquery.com
.jsononline.com
.jstor.org
.justice.gov
.jwplatform.com
.kde.org
.kernel.org
.keybase.io
.khanacademy.org
.knowyourmeme.com
.landrover.com
.last.fm
.latimes.com
.letsencrypt.org
.lighttpd.net
.linuxforums.org
.litmos.com
.lkml.org
.llvm.org
.loc.gov
.logicalincrements.com
.lowes.com
.lwn.net
.lycos.com
.mail-archive.com
man.openbsd.org
.mapquest.com
.marc.info
.marriott.com
.marshalls.com
.mathoverflow.com
.matrix.org
.media.tumblr.com
.medium.com
meet.google.com
.meetup.com
.metafilter.com
.minus.com
.mit.edu
.morganstanley.com
.mozaws.net
.mozilla.net
.mozilla.org
.msi.com
.namecheap.com
.nasa.gov
.nationalreview.com
.nbcuni.com
.ncbi.nlm.nih.gov
.netdna-ssl.com
.netflix.com
.newegg.com
.neweggimages.com
.nflxext.com
.nih.gov
.noaa.gov
.npr.org
.nsf.gov
.nxlfimg.net
.nypost.com
.nytimes.com
.oktacdn.com
.okta.com
.oneplus.com
.openh264.org
.openra.net
.openstreetmap.org
.openvpn.net
.openvpn.org
.optionstrat.com
.optoutprescreen.com
.overstock.com
.ovh.com
.ovh.net
.ovh.us
.parallels.com
.paypal.com
.pcengines.ch
.pcpartpicker.com
.phoronix.com
.photobucket.com
.phys.org
.phys.uwm.edu
.pinboard.in
.pinimg.com
.pinterest.com
.plos.org
.porscheusa.com
.potterybarn.com
.princeton.edu
.pythonhosted.org
.python.org
.quoracdn.net
.quora.com
.qz.com
.radioreference.com
.reason.com
.recaptcha.net
.redd.it
.reddit.com
.redditmedia.com
.redditstatic.com
.reddituploads.com
.redfin.com
.redhat.com
.rei.com
.researchgate.net
.reuters.com
.rolex.com
.rottentomatoes.com
.rust-lang.org
.salesforce.com
.samsung.com
.scene7.com
.schwab.com
.sciencemag.org
.scribdassets.com
.scribd.com
.sec.gov
.sec.report
.senate.gov
.serverfault.com
.shipstation.com
.shodan.io
.shopify.com
.signal.org
.slack.com
.slack-edge.com
.slack-imgs.com
.slideshare.net
.smh.com.au
.soundcloud.com
.sourceforge.net
.spacetelescope.org
.spaceweather.com
.sparkpostmail.com
.splunk.com
.squarespace-cdn.com
.squarespace.com
.sstatic.net
.stackauth.com
.stackexchange.com
.stackoverflow.com
.startpage.com
.state.gov
.staticflickr.com
.steamcommunity.com
.steampowered.com
.steamstatic.com
.streamable.com
.suckless.org
.superuser.com
.swappa.com
.symantec.com
.tableau.com
.tableausoftware.com
.target.com
.t.co
.teamspeak.com
.techdirt.com
.teddit.net
.theguardian.com
.thehill.com
.thehomedepot.com
.theverge.com
.thinkprogress.org
.timex.com
.tomshardware.com
.tonic.to
.torproject.org
.tractorsupply.com
.tradingview.com
.tripadvisor.com
.trulia.com
.trumba.com
.tumblr.com
.turbotax.com
.twimg.com
.twitch.tv
.twitter.com
.typepad.com
.ubuntuforums.org
.uhaul.com
.ui.com
.undeadly.org
.unicef.org
.ups.com
.usatoday.com
.usembassy.gov
.usgs.gov
.usps.com
.vanguard.com
.verizon.com
.verizonwireless.com
.vice.com
.videolan.org
.vimeocdn.com
.vimeo.com
.vine.co
.virustotal.com
.vsco.co
.w1.fi
.w3.org
.walgreens.com
.walmart.com
.walmartimages.com
.washingtonpost.com
.wayfair.com
.weather.gov
.wellsfargo.com
.whispersystems.org
.whitehouse.gov
.wikibooks.org
wiki.debian.org
.wikimedia.org
.wikipedia.org
.wikiquote.org
.wiktionary.org
.wired.com
.wireshark.org
.wix.com
.wmflabs.org
.woot.com
.wordpress.com
.wordpress.org
.w.org
.wp.com
.wp.org
.wsj.com
www.debian.org
www.openbsd.org
.xfinity.com
.yahooapis.com
.yahoo.com
.yahoo.net
.ycombinator.com
.yelpcdn.com
.youtu.be
.youtube.com
.youtube-dl.org
.youtube-nocookie.com
.ytimg.com
.yubico.com
.zappos.com
.zillow.com
.zillowstatic.com
.zlcdn.com
{ -redirect{android} }
connectivitycheck.gstatic.com/generate_204
#{+hide-user-agent{Mozilla/5.0 (Windows NT 10.0; rv:68.0) Gecko/20100101 Firefox/68.0}}
#/
" | sudo tee /etc/privoxy/user.action

sudo systemctl restart privoxy.service; systemctl status privoxy.service
