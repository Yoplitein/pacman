module pacman.globals;

import gfm.sdl2;

import pacman.grid;
import pacman.player;

enum WIDTH = 800;
enum HEIGHT = 600;
enum TILE_SIZE = 32;

SDL2 sdl;
SDLImage sdlImage;
SDL2Window window;
SDL2Renderer renderer;
Grid grid;
Player player;
real timeSeconds;
real timeDelta;
