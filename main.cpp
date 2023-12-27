#include <iostream>
#include <map>
#include <set>
#include <string>
#include <cmath>
#include <vector>
#include <algorithm>
#include <unordered_map>
#include <numeric>
#include <iomanip>
#include <iostream>
#include <SDL.h>
#include <queue>
#include <stack>

using namespace std;

const int SCREEN_WIDTH = 600;
const int SCREEN_HEIGHT = 600;
const int GRID_SIZE = 30;
const int CELL_SIZE = SCREEN_WIDTH / GRID_SIZE;


SDL_Window* gWindow = nullptr;
SDL_Renderer* gRenderer = nullptr;

// Pair of integers to represent a cell (x, y)
using CellPair = std::pair<int, int>;

struct Grid {
    // Attributes
    int width = 600;
    int height = 600;
    int cellSize = 20;

    //0 = white, 1 = black, 2 = green, 3 = red
    int startColor = 2;
    int endColor = 3;
    int emptyCellColor = 0;
    int blockedCellColor = 1;

    bool isStartDefined = false;
    bool isEndDefined = false;

    CellPair startCell = {-1,-1};
    CellPair endCell = {-1,-1};

    std::vector<std::vector<int>> data;
    std::map<pair<int, int>, int> rectColor;
    std::vector<CellPair> path_bfs;
    std::vector<CellPair> path_dfs;

    // Constructor
    Grid(int w, int h, int cellSize) : width(w), height(h), cellSize(cellSize), startCell({-1,-1}), endCell({-1,-1}) {
        data.resize(height, std::vector<int>(width, 0));
    }

    // Draw function
    void draw(SDL_Renderer* renderer) const {
        for (int i = 0; i < height; i++) {
            for (int j = 0; j < width; j++) {
                SDL_Rect cellRect = {j * cellSize, i * cellSize, cellSize, cellSize};

                CellPair currentCell = {i, j};
                auto isInBFSPath = [this, &currentCell](const CellPair& cell) {
                    return std::find(path_bfs.begin(), path_bfs.end(), cell) != path_bfs.end();
                };

                auto isInDFSPath = [this, &currentCell](const CellPair& cell) {
                    return std::find(path_dfs.begin(), path_dfs.end(), cell) != path_dfs.end();
                };

                bool isBFSPathCell = isInBFSPath(currentCell);
                bool isDFSPathCell = isInDFSPath(currentCell);

                if (currentCell == startCell) {
                    SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255); // Green for start cell
                } else if (currentCell == endCell) {
                    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255); // Red for end cell
                } else if (isDFSPathCell) {
                    SDL_SetRenderDrawColor(renderer, 255, 165, 0, 255); // Orange for cells in the DFS path
                    SDL_RenderFillRect(renderer, &cellRect); // Fill the rectangle with the specified color
                }else if (isBFSPathCell) {
                    SDL_SetRenderDrawColor(renderer, 255, 255, 0, 255); // Yellow for cells in the BFS path
                } else {
                    // Set color based on the cell's value in the data vector
                    if (data[i][j] == 0) {
                        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255); // White for unblocked cells
                    } else if (data[i][j] == 1) {
                        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); // Black for blocked cells
                    } else {
                        // Handle other colors if needed
                    }
                }

                SDL_RenderFillRect(renderer, &cellRect);

                if (!isDFSPathCell && !isBFSPathCell) {
                    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); // Reset color to black for cell border
                    SDL_RenderDrawRect(renderer, &cellRect);
                }
            }
        }
    }


    void handleMouseClickEvent(SDL_Event& e, Grid& grid) {
        if (e.type == SDL_QUIT) {
            this->closeSDL();
            exit(0);
        } else if (e.type == SDL_MOUSEBUTTONDOWN) {
            int mouseX, mouseY;
            SDL_GetMouseState(&mouseX, &mouseY);

            int cellX = mouseX / grid.cellSize;
            int cellY = mouseY / grid.cellSize;
            pair<int, int> currCell = make_pair(cellY, cellX);

            cout<<"Curr cell " << cellX << " " << cellY <<endl;
            cout<<grid.data[cellY][cellX]<<endl;

            if (grid.data[cellY][cellX] != emptyCellColor){
                if (rectColor[currCell] == startColor){
                    isStartDefined = false;
                    grid.data[cellY][cellX] = emptyCellColor;
                    rectColor[currCell] = emptyCellColor;
                    grid.startCell = {-1, -1}; // Set to an invalid value
                }
                else if (rectColor[currCell] == endColor){
                    isEndDefined = false;
                    grid.data[cellY][cellX] = emptyCellColor;
                    rectColor[currCell] = emptyCellColor;
                    grid.endCell = {-1,-1};
                }
                else{
                    grid.data[cellY][cellX] = emptyCellColor;
                    rectColor[currCell] = emptyCellColor;
                }
            }
            else{
                if(isStartDefined){
                    if(isEndDefined){
                        grid.data[cellY][cellX] = blockedCellColor;
                        rectColor[currCell] = blockedCellColor;
                    }
                    else{
                        grid.data[cellY][cellX] = endColor;
                        rectColor[currCell] = endColor;
                        isEndDefined = true;
                        endCell = currCell;
                    }
                } else{
                    grid.data[cellY][cellX] = startColor;
                    rectColor[currCell] = startColor;
                    startCell = currCell;
                    isStartDefined = true;
                }
            }
        }
        else if(e.type == SDL_KEYDOWN){
            vector <CellPair> blocked_cells;
            for (auto x : rectColor){
                if(x.second == 1){
                    blocked_cells.push_back(x.first);
                }
            }
            if(e.key.keysym.sym == SDLK_b){//User pressed "B" key
               vector <CellPair> path_bfs = bfs_path(startCell, endCell, blocked_cells);
                for (auto x : path_bfs){
                    cout << x.first << " " << x.second << endl;
                }
            }
            else if(e.key.keysym.sym == SDLK_d) {//User pressed "D" key
                path_dfs = dfs_path(startCell, endCell, blocked_cells);
                for (auto y : path_dfs) {
                    cout << y.first << " " << y.second << endl;
                }
            }
        }
    }


    vector <CellPair> bfs_path(CellPair &start_cell, CellPair &end_cell, vector <CellPair> &blocked_cells){
        // Define directions for moving to neighboring cells (up, down, left, right)
        const vector<int> dx = {0, 0, -1, 1};
        const vector<int> dy = {-1, 1, 0, 0};

        // Initialize visited status for each cell
        vector<vector<bool>> visited(height, vector<bool>(width, false));

        // Initialize queue for BFS
        queue<pair<CellPair, vector<CellPair>>> bfs_queue;
        bfs_queue.push({start_cell, {start_cell}});

        while (!bfs_queue.empty()) {
            auto current = bfs_queue.front();
            bfs_queue.pop();

            CellPair current_cell = current.first;
            vector<CellPair> current_path = current.second;

            // Check if the current cell is the destination
            if (current_cell == end_cell) {
                path_bfs = current_path;  // Update the member variable with the found path
                return path_bfs;  // Return the path if destination is reached
            }

            // Explore neighbors
            for (int i = 0; i < 4; ++i) {
                int next_x = current_cell.second + dx[i];
                int next_y = current_cell.first + dy[i];
                CellPair next_cell = {next_y, next_x};

                // Check if the next cell is within the grid bounds
                if (next_x >= 0 && next_x < width && next_y >= 0 && next_y < height) {
                    // Check if the next cell is not blocked and not visited
                    if (find(blocked_cells.begin(), blocked_cells.end(), next_cell) == blocked_cells.end() &&
                        !visited[next_y][next_x]) {
                        visited[next_y][next_x] = true;
                        vector<CellPair> next_path = current_path;
                        next_path.push_back(next_cell);
                        bfs_queue.push({next_cell, next_path});
                    }
                }
            }
        }

        path_bfs.clear();  // Clear the member variable if no path is found
        return path_bfs;
    }

    vector<CellPair> dfs_path(CellPair &start_cell, CellPair &end_cell, vector<CellPair> &blocked_cells) {
        // Define directions for moving to neighboring cells (up, down, left, right)
        const vector<int> dx = {0, 0, -1, 1};
        const vector<int> dy = {-1, 1, 0, 0};

        // Initialize visited status for each cell
        vector<vector<bool>> visited(height, vector<bool>(width, false));

        // Initialize stack for DFS
        stack<pair<CellPair, vector<CellPair>>> dfs_stack;
        dfs_stack.push({start_cell, {start_cell}});

        while (!dfs_stack.empty()) {
            auto current = dfs_stack.top();
            dfs_stack.pop();

            CellPair current_cell = current.first;
            vector<CellPair> current_path = current.second;

            // Check if the current cell is the destination
            if (current_cell == end_cell) {
                return current_path;  // Return the path if the destination is reached
            }

            // Explore neighbors
            for (int i = 0; i < 4; ++i) {
                int next_x = current_cell.second + dx[i];
                int next_y = current_cell.first + dy[i];
                CellPair next_cell = {next_y, next_x};

                // Check if the next cell is within the grid bounds
                if (next_x >= 0 && next_x < width && next_y >= 0 && next_y < height) {
                    // Check if the next cell is not blocked and not visited
                    if (find(blocked_cells.begin(), blocked_cells.end(), next_cell) == blocked_cells.end() &&
                        !visited[next_y][next_x]) {
                        visited[next_y][next_x] = true;
                        vector<CellPair> next_path = current_path;
                        next_path.push_back(next_cell);
                        dfs_stack.push({next_cell, next_path});
                    }
                }
            }
        }

        // If no path is found, return an empty vector
        return {};
    }


    void closeSDL() {
        SDL_DestroyRenderer(gRenderer);
        SDL_DestroyWindow(gWindow);
        SDL_Quit();
    }



};

// Initialization function
bool initSDL() {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL initialization failed: " << SDL_GetError() << std::endl;
        return false;
    }

    gWindow = SDL_CreateWindow("Path Visualizer", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
    if (gWindow == nullptr) {
        std::cerr << "Window creation failed: " << SDL_GetError() << std::endl;
        return false;
    }

    gRenderer = SDL_CreateRenderer(gWindow, -1, SDL_RENDERER_ACCELERATED);
    if (gRenderer == nullptr) {
        std::cerr << "Renderer creation failed: " << SDL_GetError() << std::endl;
        return false;
    }

    return true;
}

// Function to close SDL
void closeSDL() {
    SDL_DestroyRenderer(gRenderer);
    SDL_DestroyWindow(gWindow);
    SDL_Quit();
}


// Function to handle SDL events
void handleEvent(SDL_Event& e, Grid& grid) {
    if (e.type == SDL_QUIT) {
        closeSDL();
        exit(0);
    } else if (e.type == SDL_MOUSEBUTTONDOWN) {
        int mouseX, mouseY;
        SDL_GetMouseState(&mouseX, &mouseY);

        int cellX = mouseX / grid.cellSize;
        int cellY = mouseY / grid.cellSize;

        if (grid.data[cellY][cellX] == 0) {
            if (grid.startCell == CellPair(-1, -1)) {
                grid.startCell = CellPair(cellY, cellX);
                grid.data[cellY][cellX] = 2;
                std::cout << "Start Cell Selected: (" << cellX << ", " << cellY << ")\n";
            }
            else if (grid.endCell == CellPair(-1, -1)) {
                grid.endCell = CellPair(cellY, cellX);
                grid.data[cellY][cellX] = 3;
                std::cout << "End Cell Selected: (" << cellX << ", " << cellY << ")\n";
            }
            else {
                // Additional logic for handling other clicks
                // blocking a cell
                if (CellPair(cellY, cellX) != grid.startCell && CellPair(cellY, cellX) != grid.endCell) {
                    grid.data[cellY][cellX] = 1;
                    cout << "Cell Blocked: (" << cellX << ", " << cellY << ")\n";
                }
            }
        }
    }
}




// Main function
// Main function
int main() {
    if (!initSDL()) {
        return 1;
    }

    SDL_Event e;

    Grid grid(GRID_SIZE, GRID_SIZE, CELL_SIZE);

    while (true) {
        while (SDL_PollEvent(&e) != 0) {
            grid.handleMouseClickEvent(e, grid);
        }

        SDL_SetRenderDrawColor(gRenderer, 255, 255, 255, 255);
        SDL_RenderClear(gRenderer);

        // Draw the grid
        grid.draw(gRenderer);

        SDL_RenderPresent(gRenderer);
    }

    grid.closeSDL();  // Call the member function to close SDL resources

    return 0;
}

