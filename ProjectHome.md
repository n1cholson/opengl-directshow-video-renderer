OpenGL DirectShow Video Renderer Filter

Supports the following color formats:

- RGB24
- RGB32
- RGB555
- RGB565
- YUY2
- UYVY
- YUYV
- YVYU
- YV12

Color format conversion is done in hardware and software.

Hardware capabilities will be used if the following OpenGL Extension are available (Opengl Version 2.1 or higher):

- GL\_ARB\_shader\_objects
- GL\_ARB\_vertex\_shader
- GL\_ARB\_fragment\_shader
- GL\_ARB\_shading\_language\_100
- GL\_ARB\_texture\_rectangle

Uses the following headers/libraries:

- DSPack directx headers (MPL 1.1)
> http://progdigy.com

- dglOpenGL header (MPL 1.1)
> http://delphigl.com