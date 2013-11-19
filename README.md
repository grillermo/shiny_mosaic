Shiny Mosaic
============

A ruby class to create rectangles that can have other rectangles inserted (without colisions), removed and found.
A solution to the packaging problem in 2d.

My first attemp, performance is untested, but works fine for small rectangles.

If you want to see what can it do, require it and run the demo function.

Features
========
* It can build grids to fit rectangles as large as you want.
* You can reduce the size of the grid to fit a multiple of your basic rectangle.
* A method to find neighbouring squares with coordinates.
* A method to find neighbouring squares with a direction.
* Can detect the limits of the enclosing rectangle.
* If there is space for your rectangle in the grid, it will fit.
* Support all sizes of rectangles.
* A few helper methods to print the grid in a console.
* If you want to build an html layout with it, you have a few helper methods to absolutely position the squares.
* A simple API to plug your objects with photos and have it output html.

TODO
====
* Improve performance in large grids, currently the algorithm does a little less than exponential time growth.
* The find neighbouring rectangles method only looks in the corners, not all the edges.
* A Python version?
* Improve docs, comments, clean up code.
    

License
-------
http://creativecommons.org/licenses/by/2.0/
