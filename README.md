# Instagram-style filters in HTML5 Canvas

[Instagram](https://www.instagram.com/) made us all fall in love with
image filters. A well-chosen filter can augment the best parts of a
photo, or soften undesirable qualities.

On a recent project I was charged with implementing similar image filters
for a JavaScript application that leans on HTML5 canvas.

So began my journey down the beautiful rabbit hole that is pixel
manipulation.

## Prior Art

Late last year
[Una Kravets gave us Instagram filters in CSS](https://github.com/una/CSSgram). The
project is an excellent example of how powerful CSS has become.

In brief, modern CSS allows one to apply a blending mode directly to a
CSS element:

<iframe src="http://codepen.io/nhunzaker/full/LNNmLm/" width="100%" height="390" frameborder="0"></iframe>

Specifically, modern CSS grants access to
[`mix-blend-mode`](https://developer.mozilla.org/en-US/docs/Web/CSS/mix-blend-mode). This
CSS property exposes the full gamut of blending modes one would expect
from a graphical image editor.

## Bringing Blend Modes to HTML5 Canvas

> "The future is already here — it's just not very evenly distributed."
>
> William Gibson

2D context canvas already supports these blend modes! However they
do not have universal browser support. In order to achieve full
browser support, the canvas image data must be manipulated
directly. Fortunately, the browser gives us really good tools for
that.

## Setting things up

We need to set up a basic environment before we can begin. We'll load
an image, then render the scene once it has finished loading:

```html
<canvas id="canvas"></canvas>

<script>
  var photo    = new Image();
  var canvas = document.getElementById('canvas');
  var ctx    = canvas.getContext('2d');

  function render () {
    // Scale so that the image fills the container
    var width  = window.innerWidth;
    var scale  = width / photo.naturalWidth;
    var height = photo.naturalHeight * scale;;

    canvas.width  = width;
    canvas.height = height;

    ctx.drawImage(photo, 0, 0);
  }

  photo.onload = render;
  photo.crossOrigin = "Anonymous";
  photo.src = "http://code.viget.com/artifacts/about-3.jpg";
</script>
```

Essentially, create a `render` function that draws an image, then call
it when the image finishes loading.

<iframe src="http://codepen.io/nhunzaker/full/xVVjJj/" width="100%" height="390" frameborder="0"></iframe>

This paints the image. However
[Ina's implementation of Toaster](https://github.com/una/CSSgram/blob/master/source/scss/toaster.scss),
there is a radial gradient on top.

This is provided by the 2D canvas API:

```javascript
function toasterGradient (width, height) {
  var texture = document.createElement('canvas');
  var ctx = texture.getContext('2d');

  texture.width = width;
  texture.height = height;

  // Fill a Radial Gradient
  // https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/createRadialGradient
  var gradient = ctx.createRadialGradient(width / 2, height / 2, 0, width / 2, height / 2, width * 0.6);

  gradient.addColorStop(0, "#804e0f");
  gradient.addColorStop(1, "#3b003b");

  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, width, height);

  return ctx;
}

function render () {
  // ... prior code

  var gradient = toasterGradient(width, height);

  ctx.drawImage(gradient.canvas, 0, 0);
}
```

We're getting there. However this leaves us with an opaque
purple-orange gradient covering our image.

<iframe src="http://codepen.io/nhunzaker/full/vGGVYo/" width="100%"
height="390" frameborder="0"></iframe>

Not ideal. We need to blend the pixels in the gradient with the
background. That means enumerating over the pixel data Canvas gives us
a great way to do that with `context.getImageData`.

## context.getImageData

`context.getImageData` grabs a box of pixels from the canvas and
returns an `ImageData` object. `ImageData` provides `width`,
`height`, and `data` properties. We only care about the `data`
field:

```javascript
function blend (background, foreground, width, height, transform) {
  var bottom = background.getImageData(0, 0, width, height);
  var top    = foreground.getImageData(0, 0, width, height);

  for (var i = 0, size = top.data.length; i < size; i += 4) {
    // red
    top.data[i+0] = transform(bottom.data[i+0], top.data[i+0]);
    // green
    top.data[i+1] = transform(bottom.data[i+1], top.data[i+1]);
    // blue
    top.data[i+2] = transform(bottom.data[i+2], top.data[i+2]);
    // the fourth slot is alpha. We don't need that (so skip by 4)
  }

  return top;
}
```

Cool. Enumerate over ever pixel of the gradient (the foreground) and
replace the pixel with the result of a given transformation function.

So what do I mean by transformation function? I mean a blending mode
transformation. This is not propriety knowledge, [Wikipedia contains a
wealth of formulas for a number of blend modes](https://en.wikipedia.org/wiki/Blend_modes).

## Implementing the screen blend mode

[According to CSSGram](https://github.com/una/CSSgram/blob/master/source/css/toaster.css#L32),
we need the "screen" blend mode for Toaster. This formula is:

```javascript
// https://en.wikipedia.org/wiki/Blend_modes#Screen
function screen (bottomPixel, topPixel) {
  return 1 - (1 - bottomPixel) * (1 - topPixel);
}
```

Since `getImageData` returns color values between 0 and 255, we need
to make a minor tweak:

```javascript
// https://en.wikipedia.org/wiki/Blend_modes#Screen
function screen (a, b) {
  bottomPixel /= 255;
  topPixel    /= 255;

  return 255 * (1 - (1 - topPixel) * (1 - bottomPixel));
}
```

Finally, let's invoke the `blend` function with this transformation:

```javascript
function render() {
  // ...prior code
  var screen = blend(ctx, gradient, width, height, function (bottomPixel, topPixel) {
    bottomPixel /= 255;
    topPixel    /= 255;

    return 255 * (1 - (1 - topPixel) * (1 - bottomPixel));
  })

  // replace `ctx.drawImage(gradient.canvas, 0, 0)` with this:
  ctx.putImageData(screen, 0, 0);
}
```

Nice! This performs the blending we want.

<iframe src="http://codepen.io/nhunzaker/full/jqqeEm/" width="100%"
height="390" frameborder="0"></iframe>

## Why is it so washed out?

We've neglected an important component: [Toaster manipulates contrast and
brightness using the CSS `filter` property](https://github.com/una/CSSgram/blob/master/source/scss/toaster.scss#L11).

Brightness and contrast are a little tricker, however the
techniques are well established. The internet is a deep ocean of free
information. Furtunately for us, [the HTML5 drawing
library EaselJS has already solved this problem for us](http://www.createjs.com/docs/easeljs/files/easeljs_filters_ColorMatrixFilter.js.html#l41). Color
matrices provide a way to manipulate the brightness, color, contrast,
and saturation of an image.

## Using Color Matrices

For the sake of keeping focused, I've extracted the color matrix
algorithm from EaselJS for the purposes of this blog post, I won't
make you wade through matrix multiplication. However feel free to
checkout
[the source code](https://gist.github.com/nhunzaker/79c599d367b168819c11)
if you are curious

After we pull in a color matrix transformation library, manipulating brightness and contrast is a matter of sending
parameters into a color matrix:

```html
<script src="color-matrix.js"></script>

<script>
  //... prior code
  function render () {
    //...prior code
    var colorCorrected = colorMatrix(screen, { contrast: 30, brightness: -30 });

    // Replace `ctx.putImageData(screen, 0, 0)` with:
    ctx.putImageData(colorCorrected, 0, 0);
  }
</script>
```

The specific brightness and contrast parameters are different, however
the effect is virtually the same. Beautiful:

<iframe src="http://codepen.io/nhunzaker/full/oxxaXO/" width="100%"
height="390" frameborder="0"></iframe>

## We made it

A quick diff from Photoshop also shows us that we hit the mark pretty
closely:

<div style="margin-bottom: 24px; font-size: 12px;">
  <img src="https://cloud.githubusercontent.com/assets/590904/13647908/41ef37c0-e604-11e5-8e1d-1f47ee77a70b.png" style="max-width: 100%; display: block; margin-bottom: 4px;"/>
  Darker pixels means a closer match.
</div>

Implementing blend modes such as `screen`, `multiply` and `color-burn`
are totally achievable; it just takes a little more work. The result
is fantastic, beautiful photography within 2D context canvas.

[View the end result for yourself.](demo.html)
