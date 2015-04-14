module pacman.globals;

import gfm.sdl2;

enum WIDTH = 800;
enum HEIGHT = 600;
enum TILE_SIZE = 32;

SDL2 sdl;
SDLImage sdlImage;
SDL2Window window;
SDL2Renderer renderer;
real timeSeconds;
real timeDelta;
