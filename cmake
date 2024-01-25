#include <iostream>
#include <map>
#include <set>
#include <string>
#include <cmath>
#include <vector>
#include <algorithm>
#include <unordered_map>
#include <numeric>
#include <thread>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <SDL.h>
#include <queue>
#include <limits>
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


    int startColor = 2;
    int endColor = 3;
    int emptyCellColor = 0;
    int blockedCellColor = 1;

    bool isStartDefined = false;
    bool isEndDefined = false;
    bool anyPathColored = false;

    CellPair startCell = {-1, -1};
    CellPair endCell = {-1, -1};

    mutable map<CellPair, int> rectColor;
    //0 = white, 1 = black, 2 = green, 3 = red, 4 = bfs path, 5 = dfs path, 6 = dij path, 7 = visualiser cell

    vector<CellPair> path_bfs;
    vector<CellPair> path_dfs;
    vector<CellPair> path_dij;
    vector<vector<int>> data;

    // Constructor
    Grid(int w, int h, int cellSize) : width(w), height(h), cellSize(cellSize), startCell({-1, -1}), endCell({-1, -1}) {
        data.resize(height, std::vector<int>(width, 0));
    }
    void setColorForCell(CellPair cell, int color) {
        rectColor[cell] = color;
    }

    // Draw function
    void draw(SDL_Renderer *renderer) const {
        for (int i = 0; i < height; i++) {
            for (int j = 0; j < width; j++) {
                SDL_Rect cellRect = {j * cellSize, i * cellSize, cellSize, cellSize};
                CellPair currentCell = {i, j};
                int colour_code_curr_cell = rectColor[currentCell];

                if (currentCell == startCell) {
                    SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255); // Green for start cell
                } else if (currentCell == endCell) {
                    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255); // Red for end cell
                } else if (colour_code_curr_cell == 5) {
                    SDL_SetRenderDrawColor(renderer, 255, 165, 0, 255); // Orange for cells in the DFS path
                    SDL_RenderFillRect(renderer, &cellRect); // Fill the rectangle with the specified color
                } else if (colour_code_curr_cell == 7) {
                    SDL_SetRenderDrawColor(renderer, 0, 0, 255, 255); // Blue color for visualiser cells
                }else if (colour_code_curr_cell == 4) {
                    SDL_SetRenderDrawColor(renderer, 255, 255, 0, 255); // Yellow for cells in the BFS path
                } else if (colour_code_curr_cell == 6) {
                    SDL_SetRenderDrawColor(renderer, 255, 182, 193, 255); // Pink color for cells in the Dij path
                    SDL_RenderFillRect(renderer, &cellRect); // Fill the rectangle with the specified color
                }
                else {
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

                if (colour_code_curr_cell != 5 && colour_code_curr_cell != 4 && colour_code_curr_cell != 6) {
                    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); // Reset color to black for cell border
                    SDL_RenderDrawRect(renderer, &cellRect);
                }
            }
        }
    }


    void handleMouseClickEvent(SDL_Event &e, Grid &grid) {
        if (e.type == SDL_QUIT) {
            this->closeSDL();
            exit(0);
        } else if (e.type == SDL_MOUSEBUTTONDOWN) {
            // if mousebutton is pressed on grid

            int mouseX, mouseY;
            SDL_GetMouseState(&mouseX, &mouseY);

            int cellX = mouseX / grid.cellSize;
            int cellY = mouseY / grid.cellSize;
            pair<int, int> currCell = make_pair(cellY, cellX);

            if (isEmptyCellColor(cellX, cellY, grid)) {
                fillEmptyCell(cellX, cellY, grid, currCell);
            } else {
                makeCellEmpty(cellX, cellY, grid, currCell);
            }

        } else if (e.type == SDL_KEYDOWN) {
            // if key is pressed
            vector<CellPair> blocked_cells;
            for (auto x: rectColor) {
                if (x.second == 1) {
                    blocked_cells.push_back(x.first);
                }
            }

            int key_pressed = e.key.keysym.sym;
            callPathFindingAlgorithm(key_pressed, startCell, endCell, blocked_cells);
        }
    }

    bool isEmptyCellColor(int cellX, int cellY, Grid &grid){
        return grid.data[cellY][cellX] == emptyCellColor;
    }
    bool isStartCellColor(int cellX, int cellY, Grid &grid){
        return grid.data[cellY][cellX] == startColor;
    }
    bool isEndCellColor(int cellX, int cellY, Grid &grid){
        return grid.data[cellY][cellX] == endColor;
    }

    void fillCellColor(int cellX, int cellY, Grid &grid, int color, CellPair currCell){
        grid.data[cellY][cellX] = color;
        rectColor[currCell] = color;
    }
    void makeCellEmpty(int cellX, int cellY, Grid &grid, CellPair currCell){
        if (isStartCellColor(cellX, cellY, grid)) {
            isStartDefined = false;
            grid.startCell = {-1, -1}; // Set to an invalid value
        } else if (isEndCellColor(cellX, cellY, grid)) {
            isEndDefined = false;
            grid.endCell = {-1, -1};
        }
        fillCellColor(cellX, cellY, grid, emptyCellColor, currCell);
    }
    void fillEmptyCell(int cellX, int cellY, Grid &grid, CellPair currCell){
        if (isStartDefined) {
            if (isEndDefined) {
                // fill black
                fillCellColor(cellX, cellY, grid, blockedCellColor, currCell);
            } else {
                // fill red
                fillCellColor(cellX, cellY, grid, endColor, currCell);
                isEndDefined = true;
                endCell = currCell;
            }
        } else {
            //fill green
            fillCellColor(cellX, cellY, grid, startColor, currCell);
            startCell = currCell;
            isStartDefined = true;
        }
    }

    void clear_path_ifany(){
        for (auto &x : rectColor){
            if(x.second == 4 or x.second == 5 or x.second == 6 or x.second == 7){
                x.second = 0;
            }
        }
        return;
    }

    void callPathFindingAlgorithm(int key_pressed, CellPair start, CellPair end, vector<CellPair> blocked_cells){
        if (key_pressed == SDLK_b) {//User pressed "B" key
            clear_path_ifany();
            path_dfs.clear();
            path_dij.clear();
            vector<CellPair> path_bfs = bfs_path(startCell, endCell, blocked_cells);
            for (auto x: path_bfs) {
                cout << x.first << " " << x.second << endl;
                rectColor[x] = 4;
            }
        } else if (key_pressed == SDLK_d) {//User pressed "D" key
            clear_path_ifany();
            path_bfs.clear();
            path_dij.clear();
            path_dfs = dfs_path(startCell, endCell, blocked_cells);
            for (auto y: path_dfs) {
                cout << y.first << " " << y.second << endl;
                rectColor[y] = 5;
            }
        } else if (key_pressed == SDLK_s) {//User pressed "S" key
            clear_path_ifany();
            path_bfs.clear();
            path_dfs.clear();
            path_dij = shortest_path(startCell, endCell, blocked_cells);
            for (auto z: path_dij) {
                cout << z.first << " " << z.second << endl;
                rectColor[z] = 6;
            }
        }
    }
    vector<CellPair> bfs_path(CellPair &start_cell, CellPair &end_cell, vector<CellPair> &blocked_cells) {
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
                for (const auto& cell : path_bfs) {
                    setColorForCell(cell, 4);  // Color the cell yellow
                    SDL_RenderClear(gRenderer);
                    draw(gRenderer);
                    SDL_RenderPresent(gRenderer);
                    SDL_Delay(50);  // Adjust the delay time (in milliseconds) as needed
                }
                return path_bfs;  // Return the path if the destination is reached
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
                        setColorForCell(next_cell, 7);  // Color the cell blue
                        SDL_RenderClear(gRenderer);
                        draw(gRenderer);
                        SDL_RenderPresent(gRenderer);
                        SDL_Delay(50);  // Adjust the delay time (in milliseconds) as needed
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
                path_dfs = current_path;  // Update the member variable with the found path
                for (const auto& cell : path_dfs) {
                    setColorForCell(cell, 5);  // Color the cell yellow
                    SDL_RenderClear(gRenderer);
                    draw(gRenderer);
                    SDL_RenderPresent(gRenderer);
                    SDL_Delay(10);  // Adjust the delay time (in milliseconds) as needed
                }
                return path_dfs;  // Return the path if the destination is reached
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
                        setColorForCell(next_cell, 7);  // Color the cell blue
                        SDL_RenderClear(gRenderer);
                        draw(gRenderer);
                        SDL_RenderPresent(gRenderer);
                        SDL_Delay(10);  // Adjust the delay time (in milliseconds) as needed
                    }
                }
            }
        }

        // If no path is found, return an empty vector
        return {};
    }

    vector<CellPair> shortest_path(CellPair &start_cell, CellPair &end_cell, vector<CellPair> &blocked_cells) {
        // Define directions for moving to neighboring cells (up, down, left, right)
        const vector<int> dx = {0, 0, -1, 1};
        const vector<int> dy = {-1, 1, 0, 0};

        // Priority queue for Dijkstra's algorithm
        priority_queue<pair<int, CellPair>, vector<pair<int, CellPair>>, greater<pair<int, CellPair>>> pq;

        // Initialize distances, visited status, and previous cell for each cell
        vector<vector<int>> distance(height, vector<int>(width, numeric_limits<int>::max()));
        vector<vector<bool>> visited(height, vector<bool>(width, false));
        vector<vector<CellPair>> previous(height, vector<CellPair>(width, {-1, -1}));

        // Start cell has distance 0
        distance[start_cell.first][start_cell.second] = 0;
        bool destinationReached = false;  //whether the destination is reached

        // Push the start cell to the priority queue
        pq.push({0, start_cell});

        while (!pq.empty()) {
            // Get the cell with the minimum distance from the priority queue
            auto current = pq.top();
            pq.pop();

            CellPair current_cell = current.second;

            // Mark the current cell as visited
            visited[current_cell.first][current_cell.second] = true;

            // Check if the current cell is the destination
            if (current_cell == end_cell) {
                destinationReached = true;  // true if destination reached
                break;  // Exit the loop if the destination is reached
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
                        int new_distance = distance[current_cell.first][current_cell.second] + 1;
                        if(!destinationReached){
                            setColorForCell(next_cell, 7);  // Color the cell blue
                            SDL_RenderClear(gRenderer);
                            draw(gRenderer);
                            SDL_RenderPresent(gRenderer);
                            SDL_Delay(10);  // Adjust the delay time (in milliseconds) as needed
                        }

                        // Update distance if a shorter path is found
                        if (new_distance < distance[next_y][next_x]) {
                            distance[next_y][next_x] = new_distance;
                            previous[next_y][next_x] = current_cell;  // Update previous cell
                            pq.push({new_distance, next_cell});

                        }
                    }
                }
            }
        }

        // Reconstruct the path
        vector<CellPair> path;
        CellPair temp = end_cell;
        while (temp != start_cell) {
            path.push_back(temp);

            // Update current cell to the previous cell in the path
            temp = previous[temp.first][temp.second];
        }

        // Reverse the path to get the correct order
        reverse(path.begin(), path.end());

        // Visualize the path with a delay
        for (const auto &cell : path) {
            setColorForCell(cell, 6);  // Color the cell pink
            SDL_RenderClear(gRenderer);
            draw(gRenderer);
            SDL_RenderPresent(gRenderer);
            SDL_Delay(10);  // Adjust the delay time (in milliseconds) as needed
        }

        path_dij = path;  // Update the member variable with the found path
        return path_dij;  // Return the path if destination is reached
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

    gWindow = SDL_CreateWindow("Path Visualizer", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH,
                               SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
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

