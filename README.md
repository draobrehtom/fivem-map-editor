# fivem-map-editor
 Unofficial FiveM Map Editor from FOXX Creations.
 
 # Discord
 https://discord.com/invite/WxBZUHgbUX
 
 # YouTube
 https://www.youtube.com/@foxxgg
 
 # Support Us
 https://www.buymeacoffee.com/foxx

# Editor Installation

Before starting to installation, make sure you joined our Discord to get all others required resources. Once your purchase our editor, you will receive the following assets:

editor2
fxmaploader
To run our editor resource, you need of course a FiveM server and MongoDB installation on your host. MongoDB is used to store players, sessions and maps.
Locate editor2 and fxmaploader to your /resources/[editor] folder.


# How to install MongoDB?

See [here](https://www.mongodb.com/languages/javascript/mongodb-and-npm-tutorial). (You need to follow only the instructions until Add MongoDB as a Dependency.) Once you are done with the installation of MongoDB, make sure to create these 3 collections under the database called editor2:

players
sessions
maps


How to configure your FiveM server to connect it with your MongoDB installation?

We recommend using a fresh and stable build of FiveM. (We also recommend using the cfx-default template without any additional resources.)

Once you are ready, make sure your FiveM server is not running.  It is a simple and open source MongoDB wrapper for FiveM. It's running on top of MongoDB Node Driver.

1. Locate mongodb wrapper resource to your /resources/[editor] folder.

2. Create a file named database.cfg and the following lines:

set mongodb_url "mongodb://localhost:27017"
set mongodb_database "editor2"

2.1 Change mongodb_url and mongodb_database variables if needed.

3. Copy created file to your server data folder (where your server.cfg file located at)

4. Add the following line to your server.cfg or execute it on your server console:
exec database.cfg

4.1 If you get any kind of module error related to mongodb, do the following:
- Run Windows Command Prompt as administrator.
- Locate to mongodb wrapper resource path with:
- cd <path to your FiveM server>/resources/[editor2]/mongodb
- Then execute the following:
 - npm init
 - npm install mongodb --save

4.2 If you want editor and its dependencies to start automatically every time you start your server, add the following to your server.cfg:
- ensure mongodb
- ensure spawnmanager
- ensure custom-objects
- ensure loadscreen
- ensure editor2

5. Start your server. Check if the editor and its dependencies are working fine.


# How to export maps from editor?

To do this, you need to authenticate yourself through our Discord server. Why? Because we have a Discord Bot, which assists you to download your maps. Therefore it must be sure that your Discord credentials are correct and actually yours, so that it doesn't send your files to anyone else. It is called foxxport, our Discord assistant, helps you establish a connection between your Discord and FiveM accounts to be able to export your maps from any server that uses our map editor. 

Go to #bot-commands , type /connect and fill in your FiveM id.
Connect any server that runs our map editor (it is only at our testing server at the moment)
Execute command xauth in game (F8 > xauth or Chat > /xauth). You will receive your authentication key within a few seconds. (/xauth)
In case you didn't receive any code, make sure to allow people to message you through Discord. Otherwise bot cannot send you messages.
Execute command xauth in game again (F8 > xauth <key> or Chat > /xauth <key>), but this time with your authentication key. (Example: /xauth XYZ-123456)


# Editor Usage

FOXX map editor allows you to create various maps for your servers. Unlike any other editor, it has sessions and its custom object sync, which minimises the server-side load.


# Entering editor mode
To start the editor, simply hit F1 while in session.


# Interface
Hit F2 to view the interface. Once the interface is shown, you are presented with three tabs: session browser, entity creator and current session.

- Session Browser
Session Browser is the tab, from which you can join, create, edit or even delete a session. You can set a custom name, maximum player slots, and even a password in case you want it to be secure. Any map created in this session, stays there. No one else can load your map(s) in different sessions.


- Entity Creator
This tab allows you to create the following: a spawnpoint M, an object or a vehicle. Spawnpoints are made to help you set base points at your map to know where to spawn players.


- Current Session
This is the tab from which you access your session options and all previously created entities in session. It has two sub-tabs:

 • Library: You have here a list of saved maps in current session and can load or export them. Map exports are made through Discord, with the help of our Discord bot.    Once you click export icon at right of the map list, you receive instantly a Discord message which includes your one time usable download link to your map.

 • Environment: This tab is all about the weather and the time at current session. Changes are permanently saved.


- Moving around the map
When you initially start the editor, you are in camera mode. You are able to use the WASD keys to move the camera and the mouse to pan the camera. While moving around, you can hold ALT to move more slowly or SHIFT to go faster.


- Starting a new map
When you are in a session, all you have to do is placing entities around. You can afterwards save your map with a new or an existing name.


- Selecting
Left click Selects or frees an entity
Right click Enables dragging with mouse controls


- Moving an entity
With the mouse:
Simply drag and drop with the right mouse button.

Or:
Select the element with left click, move around the map and right click again to drop selected entity off. You can also adjust the Hold distance of an entity toward and away from the camera with mouse wheel.


With the keyboard:
Select entity with left click. Use the arrow keys to move the element in the horizontal plane, and PgUp/PgDn to move it vertically. Hold ALT to decrease the movement speed, or SHIFT to increase it.


# Rotating
With the mouse:
You can rotate selected entities around the Z axis with the mouse wheel while holding Left CTRL.


With the keyboard:
Select the element with left click. While holding CTRL (the selection marker will turn yellow), use the arrow keys and PgUp/PgDn to rotate the element around the different axes.

With both methods you can additionally hold ALT to decrease the rotation speed or SHIFT to increase it. 


# Changing entity properties
Select an entity with left click, hit F3 to change it's coords, rotation, visibility, alpha, texture and much more. You can cancel any action simply by clicking Cancel.


# Cloning
Select an entity with left click and hit C at keyboard.


# Deleting
Select an entity with left click and hit DEL at keyboard.


# Test Mode
To enter test mode, hit F5 when editor is enabled. Hit F5 again to exit Test Mode anytime.


# Movement Recorder
You may need to record your movements during Test Mode, hit K to do this.

# Axes Lock
Select an entity and hit X. Entity will be moved on its axes from now on.
