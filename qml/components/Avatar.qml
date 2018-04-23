import QtQuick 2.0

import ".."

Canvas {

    property var parts: ({})
    property bool small: false

    property bool loaded: false

    property var imageCollection: ({})

    onPartsChanged: requestPaint();
    onSmallChanged: requestPaint();

    onImageLoaded: requestPaint();

    onPaint: {
        var imagesLoaded = 0, imagesCount = 0;

        // Mark all images as unused
        for (var imageUrl in imageCollection) imageCollection[imageUrl] = false;

        // Load images that are necessary, mark images still used
        for (var part in parts) {
            if (small && _bigParts.indexOf(part) > -1) continue;
            var partUrl = parts[part];
            if (!partUrl) continue;
            ++imagesCount;
            imageCollection[partUrl] = true;
            if (!isImageLoaded(partUrl) && !isImageLoading(partUrl) && !isImageError(partUrl)) {
                loadImage(partUrl);
            }
            if (isImageLoaded(partUrl) || isImageError(partUrl)) {
                ++imagesLoaded;
            }
        }

        // Unload unused images
        Object.keys(imageCollection).forEach(function (url) {
            if (imageCollection[url] === false) {
                unloadImage(url);
                delete imageCollection[url];
            }
        });

        // If images are still not loaded, do not display
        if (imagesLoaded !== imagesCount || imagesCount == 0) {
            loaded = false;
            return;
        }

        // Render the avatar, show it
        loaded = true;

        var ctx = getContext("2d");
        if (!available || !ctx) {
            print("Impossible to draw: ", available, "/", ctx)
            return;
        }

        if (small) {
            context.setTransform(width / 90, 0, 0, height / 90, -24 * width / 90, 0);
        } else {
            context.setTransform(width / 140, 0, 0, height / 147, 0, 0);
        }

        ctx.clearRect(0, 0, 140, 147);

        if (!small) {
            drawImageIfAvailable(ctx, parts.background, 0, 0);
            drawImageIfAvailable(ctx, parts.mountBody, 24, 18);
        }

        // Draw parts in order
        [ "chair", "back", "skin", "shirt", "armor", "body", "bangs", "base", "mustache",
          "beard", "eyewear", "head", "headAccessory", "flower", "shield", "weapon", "zzz",
        ].every(function (part) {
            drawImageIfAvailable(ctx, parts[part], 24, small || parts.mountBody ? 0 : 24);
            return true;
        });

        if (!small) {
            drawImageIfAvailable(ctx, parts.mountHead, 24, 18);
            drawImageIfAvailable(ctx, parts.pet, 0, 48);
        }
    }

    function drawImageIfAvailable(ctx, url, x, y) {
        if (url && isImageLoaded(url)) {
            ctx.drawImage(url, x, y);
        }
    }

    property var _bigParts: ([ "background", "mountBody", "mountHead", "pet" ])

    Connections {
        target: Signals
        onApplicationActive: requestPaint();
    }

}
