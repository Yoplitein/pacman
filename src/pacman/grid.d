module pacman.grid;

import std.conv;
import std.exception;
import std.experimental.logger;
import std.file;
import std.json;

import gfm.sdl2;

import pacman;
import pacman.texture;
import pacman.globals;
import pacman.wallgen;

enum TileType
{
    NONE,
    WALL,
    FLOOR,
    TASTY_FLOOR, //floor with a dot
    PLAYER_SPAWN,
    
    max, //special value to test validity in to_tile_type
}

struct Tile
{
    TileType type;
    WallShape shape = WallShape.init;
}

TileType to_tile_type(long value)
{
    enforce(value >= 0 && value < cast(long)TileType.max, "Invalid tile type: " ~ value.to!string);
    
    return cast(TileType)value;
}

final class Grid
{
    immutable  vec2i[Direction] directionOffsets;
    SDL2Texture[TileType] textures;
    vec2i size;
    vec2i playerSpawn;
    Tile[] tiles;
    
    this()
    {
        immutable north = vec2i(0, -1);
        immutable east = vec2i(1, 0);
        immutable south = vec2i(0, 1);
        immutable west = vec2i(-1, 0);
        vec2i[Direction] offsets;
        offsets[Direction.NORTH] = north;
        offsets[Direction.EAST] = east;
        offsets[Direction.SOUTH] = south;
        offsets[Direction.WEST] = west;
        offsets[Direction.NORTH_EAST] = north + east;
        offsets[Direction.NORTH_WEST] = north + west;
        offsets[Direction.SOUTH_EAST] = south + east;
        offsets[Direction.SOUTH_WEST] = south + west;
        textures[TileType.WALL] = load_texture("res/wall.png");
        textures[TileType.FLOOR] = load_texture("res/floor.png");
        textures[TileType.TASTY_FLOOR] = load_texture("res/tasty_floor.png");
        textures[TileType.max] = load_texture("res/missing.png");
        
        offsets.rehash;
        textures.rehash;
        
        directionOffsets = offsets.assumeUnique;
    }
    
    ~this()
    {
        foreach(texture; textures.values)
            texture.close;
    }
    
    void load(string path)
    {
        info("Loading map from ", path);
        
        auto text = path.readText;
        auto json = text.parseJSON;
        size.x = cast(int)json["width"].integer;
        size.y = cast(int)json["height"].integer;
        tiles.length = size.x * size.y;
        size_t index;
        JSONValue[] mapData = json["tiles"].array;
        
        infof("Map is %d by %d, tile data is of length %d (expecting %d)", size.x, size.y, mapData.length, tiles.length);
        enforce(mapData.length == tiles.length, "Map data has invalid length");
        
        foreach(tileID; mapData)
            switch(tileID.integer)
            {
                case TileType.PLAYER_SPAWN:
                    size_t x = index % size.x;
                    size_t y = index / size.x;
                    playerSpawn = vec2i(cast(int)x, cast(int)y);
                    tileID = JSONValue(cast(int)TileType.FLOOR);
                    
                    goto default;
                default:
                    tiles[index++] = Tile(tileID.integer.to_tile_type);
            }
        
        foreach(y; 0 .. size.y)
            foreach(x; 0 .. size.x)
            {
                immutable pos = vec2i(x, y);
                Tile *tile = this[pos];
                Direction[] adjacentWalls;
                
                if(tile.type != TileType.WALL)
                    continue;
                
                foreach(direction, offset; directionOffsets)
                {
                    immutable otherPos = pos + offset;
                    
                    if(!exists(otherPos))
                        continue;
                    
                    if(this[otherPos].type == TileType.WALL)
                        adjacentWalls ~= direction;
                }
                
                tile.shape = WallShape(adjacentWalls);
                
                infof("wall at %s has adjacent walls %s", pos, tile.shape.endpoints);
                
                if(tile.shape !in wallTextures)
                    warning("No texture for ", tile.shape);
            }
    }
    
    void render()
    {
        foreach(y; 0 .. size.y)
            foreach(x; 0 .. size.x)
            {
                Tile *tile = this[vec2i(x, y)];
                SDL2Texture texture;
                
                switch(tile.type) with(TileType)
                {
                    case WALL:
                        auto item = tile.shape in wallTextures;
                        
                        if(item is null)
                        {
                            //warning("Missing texture for shape ", tile.shape);
                            
                            goto default;
                        }
                        else
                            texture = *item;
                        
                        break;
                    case FLOOR:
                    case TASTY_FLOOR:
                        texture = textures[tile.type];
                        
                        break;
                    case PLAYER_SPAWN:
                        continue;
                    default:
                        texture = textures[TileType.max];
                }
                
                renderer.copy(texture, x * TILE_SIZE, y * TILE_SIZE);
            }
    }
    
    size_t coords_to_index(inout vec2i position)
    {
        return position.y * size.y + position.x;
    }
    
    bool exists(inout vec2i position)
    {
        immutable index = coords_to_index(position);
        
        return index >= 0 && index < tiles.length;
    }
    
    bool solid(inout vec2i position)
    {
        TileType type = this[position].type;
        
        return type == TileType.WALL;
    }
    
    Tile *opIndex(inout vec2i position)
    {
        enforce(tiles.length > 0, "Accessing tiles on an uninitialized map");
        enforce(exists(position), "Attempting to access a tile that is out of bounds");
        
        return &(tiles[coords_to_index(position)]);
    }
}
