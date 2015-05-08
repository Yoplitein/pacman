module pacman.globals;

import gfm.sdl2;
import gfm.opengl;

import pacman.grid;
import pacman.player;
import pacman.ghost;
import pacman.renderer;

enum WIDTH = 800;
enum HEIGHT = 600;
enum TEXTURE_SIZE = 32;
enum TILE_SIZE = TEXTURE_SIZE;

SDL2 sdl;
SDLImage sdlImage;
SDL2Window window;
OpenGL opengl;
//SDL2Renderer renderer;
Renderer renderer;
Grid grid;
Player player;
Ghost ghost;
real timeSeconds;
real timeDelta;
