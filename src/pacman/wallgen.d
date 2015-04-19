module pacman.wallgen;

import std.algorithm;
import std.array;
import std.exception;
import std.experimental.logger;
import std.traits;

import gfm.sdl2;

import pacman;
import pacman.globals;

SDL2Texture[Wall] wallTextures;
private SDL2Surface renderTarget;
private SDL2Renderer lineRenderer;

enum Direction
{
    NORTH,
    NORTH_EAST,
    NORTH_WEST,
    EAST,
    SOUTH,
    SOUTH_EAST,
    SOUTH_WEST,
    WEST,
}

struct Wall
{
    immutable Direction[] endpoints;
    alias endpoints this;
    
    @disable this();
    
    //sorts the array so the hashes work out properly in the texure map
    this(inout Direction[] endpoints)
    {
        enforce(endpoints.length >= 2);
        
        Direction[] intermediate = endpoints.dup;
        
        this.endpoints = std.algorithm.sort(intermediate).array;
    }
    
}

private vec2i coordinates(Direction direction)
{
    vec2 floating()
    {
        final switch(direction) with(Direction)
        {
            case NORTH:
                return vec2(0.5, 0);
            case NORTH_EAST:
                return vec2(1, 0);
            case NORTH_WEST:
                return vec2(0, 0);
            case EAST:
                return vec2(1, 0.5);
            case SOUTH:
                return vec2(0.5, 1);
            case SOUTH_EAST:
                return vec2(1, 1);
            case SOUTH_WEST:
                return vec2(0, 1);
            case WEST:
                return vec2(0, 0.5);
        }
    }
    
    return cast(vec2i)(floating * TILE_SIZE);
}

private void generate_texture(Wall wall)
{
    immutable midPos = cast(vec2i)(vec2(0.5, 0.5) * TILE_SIZE);
    
    lineRenderer.setColor(0, 0, 0, 0);
    lineRenderer.clear;
    lineRenderer.setColor(0, 140, 255, 255);
    
    foreach(endpoint; wall)
    {
        vec2i endPos = endpoint.coordinates;
        
        lineRenderer.drawLine(endPos.x, endPos.y, midPos.x, midPos.y);
    }
    
    lineRenderer.present;
    
    
    wallTextures[wall] = new SDL2Texture(renderer, renderTarget);
}

void generate_wall_textures()
{
    renderTarget = new SDL2Surface(
        sdl,
        TEXTURE_SIZE, TEXTURE_SIZE, //size
        32, //depth
        0x00FF0000, //r
        0x0000FF00, //g
        0x000000FF, //b
        0xFF000000, //a
    );
    lineRenderer = new SDL2Renderer(renderTarget);
    immutable Direction[] all = [EnumMembers!Direction];
    
    foreach(start; all)
    {
        Direction[] choices = all.dup.filter!(direction => direction != start).array;
        
        while(choices.length > 0)
        {
            Wall wall = Wall([start] ~ choices);
            choices = choices[1 .. $];
            
            if(wall !in wallTextures)
                generate_texture(wall);
        }
    }
    
    infof("Generated %d wall textures", wallTextures.length);
}

void cleanup_wall_textures()
{
    foreach(texture; wallTextures.values)
        texture.close;
    
    lineRenderer.close;
    renderTarget.close;
}
