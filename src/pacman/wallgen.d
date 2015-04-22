module pacman.wallgen;

import std.algorithm;
import std.array;
import std.exception;
import std.experimental.logger;
import std.traits;

import gfm.sdl2;

import pacman;
import pacman.globals;

SDL2Texture[WallShape] wallTextures;
private SDL2Surface renderTarget;
private SDL2Renderer lineRenderer;

enum Direction
{
    NORTH,
    EAST,
    SOUTH,
    WEST,
    NORTH_EAST,
    SOUTH_EAST,
    NORTH_WEST,
    SOUTH_WEST,
}

struct WallShape
{
    private Direction[] _endpoints;
    
    @disable this();
    
    //sorts the array so the hashes work out properly in the texture map
    this(inout Direction[] endpoints)
    {
        Direction[] intermediate = endpoints.dup;
        //info("pre: ", intermediate);
        _endpoints = std.algorithm.sort(intermediate).array;
        //info("post: ", _endpoints);
    }
    
    const(Direction[]) endpoints()
    {
        return _endpoints;
    }
}

private vec2i coordinates(Direction direction)
{
    vec2 floating()
    {
        immutable north = vec2(0, -0.5);
        immutable east = vec2(0.5, 0);
        immutable south = vec2(0, 0.5);
        immutable west = vec2(-0.5, 0);
        immutable origin = vec2(0.5, 0.5);
        
        final switch(direction) with(Direction)
        {
            case NORTH:
                return origin + north;
            case NORTH_EAST:
                return origin + north + east;
            case NORTH_WEST:
                return origin + north + west;
            case EAST:
                return origin + east;
            case SOUTH:
                return origin + south;
            case SOUTH_EAST:
                return origin + south + east;
            case SOUTH_WEST:
                return origin + south + west;
            case WEST:
                return origin + west;
        }
    }
    
    return cast(vec2i)(floating * TILE_SIZE);
}

private void generate_texture(WallShape wall)
{
    immutable midPos = cast(vec2i)(vec2(0.5, 0.5) * TILE_SIZE);
    
    lineRenderer.setColor(0, 0, 0, 0);
    lineRenderer.clear;
    lineRenderer.setColor(0, 140, 255, 255);
    
    foreach(endpoint; wall.endpoints)
    {
        vec2i endPos = endpoint.coordinates;
        
        lineRenderer.drawLine(midPos.x, midPos.y, endPos.x, endPos.y);
    }
    
    lineRenderer.present;
    info("Generated texture for ", wall);
    
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
            WallShape wall = WallShape([start] ~ choices);
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
