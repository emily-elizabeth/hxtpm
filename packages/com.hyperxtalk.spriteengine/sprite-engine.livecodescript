script "com.hyperxtalk.library.spriteengine"

-- Sprite Engine for HyperXTalk
-- A friendly script API that wraps the com.hyperxtalk.sprite widget.
--
-- QUICK START
-- -----------
-- 1. Place a "Sprite Canvas" widget on your card and name it (e.g. "GameCanvas").
-- 2. Call setSpriteCanvas "GameCanvas" once (or rely on auto-detection).
-- 3. Use the commands below to build your game.
-- 4. Handle "tick" and "spriteCollision" messages in your card script.
--
-- EXAMPLE CARD SCRIPT
-- --------------------
--   on openCard
--       setSpriteCanvas "GameCanvas"
--       createSprite "player", specialFolderPath("resources") & "/hero.png"
--       setSpritePosition "player", 100, 100
--       setSpriteVelocity "player", 2, 0
--   end openCard
--
--   on spriteTick
--       -- Bounce off right edge
--       variable tInfo
--       put spriteInfo("player") into tInfo
--       if item 2 of tInfo > 400 then
--           setSpriteVelocity "player", -2, 0
--       end if
--   end spriteTick
--
--   on spriteCollision pA, pB
--       answer "Sprites" && pA && "and" && pB && "collided!"
--   end spriteCollision
--
-- KEY TRACKING
-- -------------
-- Put keyDown / keyUp handlers directly in your CARD SCRIPT. The card
-- receives key events naturally when no other control has keyboard focus.
-- If you click the sprite canvas it may take focus; when it does, the widget
-- forwards keyDown/keyUp back to the card automatically.
--
-- For smooth controls (checking which keys are *held*), track them yourself:
--
--   global gKeysDown
--   on keyDown k
--       if k is not among the items of gKeysDown then
--           put k & "," after gKeysDown
--       end if
--   end keyDown
--   on keyUp k
--       put replaceText(gKeysDown, k & ",", "") into gKeysDown
--   end keyUp
--
--   Then in your tick handler:
--   on spriteTick
--       if "w" is among the items of gKeysDown then setSpriteVelocity "player", 0, -3
--       if "s" is among the items of gKeysDown then setSpriteVelocity "player", 0, 3
--   end spriteTick


-- ---------------------------------------------------------------------------
-- Internal: resolve an image source to a file path
-- ---------------------------------------------------------------------------

-- spriteResolveImage(pSource)
-- Accepts either a file path or the name of a HyperXTalk image object.
-- Stack images are exported to a temp PNG so LCB always gets a real file path.
-- Returns empty if the source is empty.
function spriteResolveImage pSource
    if pSource is empty then return empty
    -- Already an existing file?
    if there is a file pSource then return pSource
    -- Named image object anywhere in this stack?
    if there is an image pSource then
        local tTempPath
        put specialFolderPath("temporary") & slash & "hxt_sprite_" & pSource & ".png" into tTempPath
        export image pSource to file tTempPath as PNG
        return tTempPath
    end if
    -- Return as-is; LCB will throw if it can't load it.
    return pSource
end spriteResolveImage


-- ---------------------------------------------------------------------------
-- Internal: locate the target widget
-- ---------------------------------------------------------------------------

local sCanvasNum  -- control number of the Sprite Canvas widget on this card

-- setSpriteCanvas pName
-- Tell the library which widget to talk to.  Call this once in openCard.
-- If you only have one Sprite Canvas on the card you can skip this;
-- the library will find it automatically.
command setSpriteCanvas pName
    local tCount, tN
    put the number of controls of this card into tCount
    repeat with tN = 1 to tCount
        if the short name of control tN of this card is pName then
            put tN into sCanvasNum
            exit repeat
        end if
    end repeat
    -- On Windows, the LCB schedule timer is unreliable so we drive the game
    -- loop from the LCS side instead.  _hxtSpriteTick sends itself repeatedly
    -- using LiveCode's own send-in-time mechanism.
    if the platform is "Win32" then
        send "_hxtSpriteTick" to me in 16 milliseconds
    end if
end setSpriteCanvas

-- Windows game loop driver.  Sends a manual "tick" command to the widget
-- then reschedules itself.  Only used when the platform is Win32.
on _hxtSpriteTick
    local tN
    put spriteCanvasNum() into tN
    if tN > 0 then
        if the running of control tN of this card then
            set the spriteCommand of control tN of this card to "manualTick"
            send "_hxtSpriteTick" to me in 16 milliseconds
        end if
    end if
end _hxtSpriteTick

-- spriteCanvasNum() ‚Äî private helper that returns the control number of the target widget.
-- Returns 0 if not found.
function spriteCanvasNum
   -- If we already have a valid control number, confirm it's still right.
   if sCanvasNum > 0 then
      if the kind of control sCanvasNum of this card is "com.hyperxtalk.sprite" then
         return sCanvasNum
      end if
      put 0 into sCanvasNum
   end if
   -- Auto-detect: find the first com.hyperxtalk.sprite widget on this card.
   local tCount, tN
   put the number of controls of this card into tCount
   repeat with tN = 1 to tCount
      if the kind of control tN of this card is "com.hyperxtalk.sprite" then
         put tN into sCanvasNum
         return sCanvasNum
      end if
   end repeat
   return 0
end spriteCanvasNum

-- spriteEngSend pCommand ‚Äî fires a command string at the widget.
command spriteEngSend pCommand
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then
        exit spriteEngSend
    end if
    set the spriteCommand of control tN of this card to pCommand
end spriteEngSend


-- ---------------------------------------------------------------------------
-- Sprite lifecycle
-- ---------------------------------------------------------------------------

-- createSprite pName [, pImagePath [, pX, pY [, pW, pH]]]
-- Create a sprite named pName.  All parameters after pName are optional.
-- If no image path is given a magenta placeholder rectangle is drawn.
command createSprite pName, pImageSource, pX, pY, pW, pH
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit createSprite
    local tCmd
    put "create," & pName into tCmd
    -- Image: resolve stack name → file path, or leave as file path.
    if pImageSource is not empty then
        put "," & spriteResolveImage(pImageSource) after tCmd
    else
        put "," after tCmd  -- empty image slot keeps element count right
    end if
    -- Numeric args travel via spriteNum1-4 to avoid LCB String→Real coercion.
    if pX is not empty then
        set the spriteNum1 of control tN of this card to pX
        set the spriteNum2 of control tN of this card to pY
        put ",pos" after tCmd   -- signals element 4 exists → use mNum1/2
        if pW is not empty then
            set the spriteNum3 of control tN of this card to pW
            set the spriteNum4 of control tN of this card to pH
            put ",size" after tCmd  -- signals element 5 exists → use mNum3/4
        end if
    end if
    set the spriteCommand of control tN of this card to tCmd
end createSprite

-- destroySprite pName
-- Soft-deletes a sprite: marks it invisible so it stops rendering and
-- participating in collisions. The sprite record stays in the engine's
-- internal list (structural list removal causes an LCB runtime fault);
-- calling createSprite with the same name reuses the slot.
command destroySprite pName
    spriteEngSend "destroy," & pName
end destroySprite

-- destroyAllSprites
-- Remove every sprite on the canvas.
command destroyAllSprites
    spriteEngSend "destroyAll"
end destroyAllSprites

-- destroySpriteGroup pGroupName
-- Remove every sprite in a group.
command destroySpriteGroup pGroupName
    spriteEngSend "destroyGroup," & pGroupName
end destroySpriteGroup


-- ---------------------------------------------------------------------------
-- Sprite properties
-- ---------------------------------------------------------------------------

-- setSpritePosition pName, pX, pY
command setSpritePosition pName, pX, pY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setSpritePosition
    set the spriteNum1 of control tN of this card to pX
    set the spriteNum2 of control tN of this card to pY
    set the spriteCommand of control tN of this card to "setPosition," & pName
end setSpritePosition

-- setSpriteVelocity pName, pVX, pVY
-- Set pixels-per-tick velocity.  The engine adds this to the position each tick.
command setSpriteVelocity pName, pVX, pVY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setSpriteVelocity
    set the spriteNum1 of control tN of this card to pVX
    set the spriteNum2 of control tN of this card to pVY
    set the spriteCommand of control tN of this card to "setVelocity," & pName
end setSpriteVelocity

-- setSpriteSize pName, pW, pH
command setSpriteSize pName, pW, pH
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setSpriteSize
    set the spriteNum1 of control tN of this card to pW
    set the spriteNum2 of control tN of this card to pH
    set the spriteCommand of control tN of this card to "setSize," & pName
end setSpriteSize

-- setSpriteVisible pName, pBool (true or false)
command setSpriteVisible pName, pBool
    if pBool then
        spriteEngSend "setVisible," & pName & ",true"
    else
        spriteEngSend "setVisible," & pName & ",false"
    end if
end setSpriteVisible

-- setSpriteImage pName, pImageSource
-- Swap the image used by an existing sprite.  Pass empty to revert to placeholder.
-- pImageSource can be a file path or a HyperXTalk image object name.
command setSpriteImage pName, pImageSource
    if pImageSource is empty then
        spriteEngSend "setImage," & pName & ","
    else
        spriteEngSend "setImage," & pName & "," & spriteResolveImage(pImageSource)
    end if
end setSpriteImage

-- setSpriteGroup pName, pGroupName
-- Assign a sprite to a named group (useful for destroySpriteGroup).
command setSpriteGroup pName, pGroupName
    spriteEngSend "setGroup," & pName & "," & pGroupName
end setSpriteGroup


-- ---------------------------------------------------------------------------
-- Reading sprite state
-- ---------------------------------------------------------------------------

-- spriteInfo(pName)
-- Returns a comma-delimited string: "name,x,y,w,h,vx,vy,visible,group"
-- Use item N of spriteInfo("player") to extract individual fields.
--   item 1 = name
--   item 2 = x          item 3 = y
--   item 4 = width      item 5 = height
--   item 6 = x velocity item 7 = y velocity
--   item 8 = visible    item 9 = group
function spriteInfo pName
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then return empty

    set the spriteCommand of control tN of this card to "query," & pName
    return the spriteCommand of control tN of this card
end spriteInfo

-- spriteX(pName), spriteY(pName), spriteW(pName), spriteH(pName)
-- Convenience functions for reading individual position/size fields.
function spriteX pName
    return item 2 of spriteInfo(pName)
end spriteX

function spriteY pName
    return item 3 of spriteInfo(pName)
end spriteY

function spriteWidth pName
    return item 4 of spriteInfo(pName)
end spriteWidth

function spriteHeight pName
    return item 5 of spriteInfo(pName)
end spriteHeight

-- allSpriteState()
-- Returns the full state of every sprite as a newline-delimited CSV string.
-- Same format as spriteInfo() per line.
function allSpriteState
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then return empty
    return the spriteState of control tN of this card
end allSpriteState

-- spritesCollide(pA, pB)
-- Manually test bounding-box overlap between two sprites.
-- The engine already posts "spriteCollision" automatically each tick;
-- use this only if you need an on-demand check.
function spritesCollide pA, pB
    local tInfoA, tInfoB
    put spriteInfo(pA) into tInfoA
    put spriteInfo(pB) into tInfoB
    if tInfoA is empty or tInfoB is empty then return false

    local tAx, tAy, tAw, tAh
    local tBx, tBy, tBw, tBh
    put item 2 of tInfoA into tAx
    put item 3 of tInfoA into tAy
    put item 4 of tInfoA into tAw
    put item 5 of tInfoA into tAh
    put item 2 of tInfoB into tBx
    put item 3 of tInfoB into tBy
    put item 4 of tInfoB into tBw
    put item 5 of tInfoB into tBh

    if (tAx + tAw) < tBx then return false
    if tAx > (tBx + tBw) then return false
    if (tAy + tAh) < tBy then return false
    if tAy > (tBy + tBh) then return false
    return true
end spritesCollide


-- ---------------------------------------------------------------------------
-- Engine control
-- ---------------------------------------------------------------------------

-- pauseSprites
-- Stop the tick loop without destroying sprites.
command pauseSprites
    local tN
    put spriteCanvasNum() into tN
    if tN > 0 then
        set the running of control tN of this card to false
    end if
end pauseSprites

-- resumeSprites
-- Restart the tick loop.
command resumeSprites
    local tN
    put spriteCanvasNum() into tN
    if tN > 0 then
        set the running of control tN of this card to true
    end if
end resumeSprites

-- setSpriteFrameRate pFPS
-- Change the tick rate (default 60).
command setSpriteFrameRate pFPS
    local tN
    put spriteCanvasNum() into tN
    if tN > 0 then
        set the frameRate of control tN of this card to pFPS
    end if
end setSpriteFrameRate

-- ---------------------------------------------------------------------------
-- Background layers
-- ---------------------------------------------------------------------------
-- Backgrounds are drawn in the order they are added (first = furthest back).
-- Each layer has its own image, scroll velocity, and stretch setting.
--
-- Single-background shorthand (backward compatible):
--   These operate on a layer named "default".
--   setSpriteBackgroundImage "Sky"
--   setSpriteBackgroundVelocity -2, 0
--   setSpriteBackgroundStretch false
--
-- Multi-layer / parallax:
--   addSpriteBackground "sky",   "FarSky",   -0.5, 0
--   addSpriteBackground "hills", "MidHills", -1.5, 0
--   addSpriteBackground "trees", "NearTrees",-3.0, 0
--   setBackgroundStretch "sky", true    -- static sky, tiles disabled
--   removeSpriteBackground "hills"
-- ---------------------------------------------------------------------------

-- setSpriteBackgroundImage pImageSource
-- Set or replace the "default" background layer (single-bg shorthand).
-- Pass empty to clear it.  Tiles by default; call setSpriteBackgroundStretch true
-- for a static stretched background instead.
command setSpriteBackgroundImage pImageSource
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setSpriteBackgroundImage
    if pImageSource is empty then
        set the spriteCommand of control tN of this card to "setBgImage,"
    else
        set the spriteCommand of control tN of this card to "setBgImage," & spriteResolveImage(pImageSource)
    end if
end setSpriteBackgroundImage

-- setSpriteBackgroundVelocity pVX, pVY
-- Scroll the "default" background layer by pVX, pVY pixels per tick.
command setSpriteBackgroundVelocity pVX, pVY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setSpriteBackgroundVelocity
    set the spriteNum1 of control tN of this card to pVX
    set the spriteNum2 of control tN of this card to pVY
    set the spriteCommand of control tN of this card to "setBgVelocity"
end setSpriteBackgroundVelocity

-- setSpriteBackgroundOffset pX, pY
-- Jump the "default" background scroll position directly.
command setSpriteBackgroundOffset pX, pY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setSpriteBackgroundOffset
    set the spriteNum1 of control tN of this card to pX
    set the spriteNum2 of control tN of this card to pY
    set the spriteCommand of control tN of this card to "setBgOffset"
end setSpriteBackgroundOffset

-- setSpriteBackgroundStretch pBool
-- true  → "default" layer stretched to fill canvas (static).
-- false → tiles and scrolls (default; good for side-scrollers).
command setSpriteBackgroundStretch pBool
    if pBool then
        spriteEngSend "setBgStretch,true"
    else
        spriteEngSend "setBgStretch,false"
    end if
end setSpriteBackgroundStretch

-- addSpriteBackground pName, pImageSource [, pVX, pVY]
-- Add (or replace) a named background layer.  Layers render in the order added.
-- pVX, pVY set the scroll velocity immediately (default 0, 0).
-- Example parallax stack:
--   addSpriteBackground "sky",   "SkyImage",   -0.5, 0
--   addSpriteBackground "hills", "HillsImage", -2,   0
--   addSpriteBackground "trees", "TreesImage", -4,   0
command addSpriteBackground pName, pImageSource, pVX, pVY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit addSpriteBackground
    local tResolved
    if pImageSource is empty then
        put empty into tResolved
    else
        put spriteResolveImage(pImageSource) into tResolved
    end if
    set the spriteCommand of control tN of this card to "addBg," & pName & "," & tResolved
    -- Set velocity if provided.
    if pVX is not empty then
        set the spriteNum1 of control tN of this card to pVX
        set the spriteNum2 of control tN of this card to pVY
        set the spriteCommand of control tN of this card to "setBgLayerVel," & pName
    end if
end addSpriteBackground

-- removeSpriteBackground pName
-- Remove a named background layer and free its image.
command removeSpriteBackground pName
    spriteEngSend "removeBg," & pName
end removeSpriteBackground

-- setBackgroundVelocity pName, pVX, pVY
-- Set the scroll velocity for a named layer.
command setBackgroundVelocity pName, pVX, pVY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setBackgroundVelocity
    set the spriteNum1 of control tN of this card to pVX
    set the spriteNum2 of control tN of this card to pVY
    set the spriteCommand of control tN of this card to "setBgLayerVel," & pName
end setBackgroundVelocity

-- setBackgroundOffset pName, pX, pY
-- Jump the scroll position of a named layer directly.
command setBackgroundOffset pName, pX, pY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setBackgroundOffset
    set the spriteNum1 of control tN of this card to pX
    set the spriteNum2 of control tN of this card to pY
    set the spriteCommand of control tN of this card to "setBgLayerOffset," & pName
end setBackgroundOffset

-- setBackgroundStretch pName, pBool
-- true  → stretch layer to fill canvas (static, no tiling).
-- false → tile and scroll (default).
command setBackgroundStretch pName, pBool
    if pBool then
        spriteEngSend "setBgLayerStretch," & pName & ",true"
    else
        spriteEngSend "setBgLayerStretch," & pName & ",false"
    end if
end setBackgroundStretch

-- setBackgroundClip pName, pLeft, pTop, pRight, pBottom
-- Restrict a background layer to a rectangular region of the canvas.
-- Tiles and scroll still work normally; drawing is just clipped to this rect.
-- Pass 0, 0, 0, 0 (or omit) to clear the clip and draw to the full canvas.
-- Example — sky only in the top half of a 400px-tall canvas:
--   setBackgroundClip "sky", 0, 0, 800, 200
command setBackgroundClip pName, pLeft, pTop, pRight, pBottom
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setBackgroundClip
    if pLeft is empty then put 0 into pLeft
    if pTop is empty then put 0 into pTop
    if pRight is empty then put 0 into pRight
    if pBottom is empty then put 0 into pBottom
    set the spriteNum1 of control tN of this card to pLeft
    set the spriteNum2 of control tN of this card to pTop
    set the spriteNum3 of control tN of this card to pRight
    set the spriteNum4 of control tN of this card to pBottom
    set the spriteCommand of control tN of this card to "setBgLayerClip," & pName
end setBackgroundClip

-- ---------------------------------------------------------------------------
-- Sprite sheet animation
-- ---------------------------------------------------------------------------

-- setSpriteSheet pName, pCols, pRows [, pFrameCount [, pInterval]]
-- Configure pName as a sprite sheet.
--   pCols      — number of frame columns in the sheet image
--   pRows      — number of frame rows
--   pFrameCount — total frames to use (default = pCols × pRows)
--   pInterval  — ticks between frame advances (default 6; at 60 fps that's 10 fps animation)
--
-- The engine divides the source image into pCols × pRows cells and cycles through
-- them automatically each tick.  Call this AFTER createSprite so the image is loaded.
--
-- Example — 4-column horizontal walk strip, 8 ticks per frame:
--   createSprite "hero", "HeroWalk"
--   setSpriteSheet "hero", 4, 1, 4, 8
command setSpriteSheet pName, pCols, pRows, pFrameCount, pInterval
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setSpriteSheet
    if pCols is empty then put 1 into pCols
    if pRows is empty then put 1 into pRows
    if pFrameCount is empty then put 0 into pFrameCount  -- 0 → widget uses cols×rows
    if pInterval is empty then put 0 into pInterval       -- 0 → widget defaults to 6
    set the spriteNum1 of control tN of this card to pCols
    set the spriteNum2 of control tN of this card to pRows
    set the spriteNum3 of control tN of this card to pFrameCount
    set the spriteNum4 of control tN of this card to pInterval
    set the spriteCommand of control tN of this card to "setSheet," & pName
end setSpriteSheet

-- setSpriteAnimation pName, pStartFrame, pEndFrame [, pInterval]
-- Set which sub-range of the sheet frames to loop (0-based indices).
-- Resets the frame counter so the new animation starts from pStartFrame immediately.
--   pInterval — ticks per frame; omit to keep the current rate.
--
-- Example — switch "hero" to a 3-frame run cycle starting at frame 4:
--   setSpriteAnimation "hero", 4, 6
command setSpriteAnimation pName, pStartFrame, pEndFrame, pInterval
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setSpriteAnimation
    if pInterval is empty then put 0 into pInterval  -- 0 → keep current
    set the spriteNum1 of control tN of this card to pStartFrame
    set the spriteNum2 of control tN of this card to pEndFrame
    set the spriteNum3 of control tN of this card to pInterval
    set the spriteCommand of control tN of this card to "setAnimation," & pName
end setSpriteAnimation

-- setSpriteFrame pName, pFrameIndex
-- Jump to a specific frame immediately (0-based).  Resets the tick counter.
-- Useful for freezing a sprite on a particular pose (e.g. idle frame 0).
command setSpriteFrame pName, pFrameIndex
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setSpriteFrame
    set the spriteNum1 of control tN of this card to pFrameIndex
    set the spriteCommand of control tN of this card to "setFrame," & pName
end setSpriteFrame

-- ---------------------------------------------------------------------------
-- Foreground layers (drawn after sprites — appear in front of everything)
-- ---------------------------------------------------------------------------
-- Use these for effects that should overlay the player: rain, snow, near trees,
-- dark cave edges, HUD overlays backed by tiling textures, etc.
-- The API is identical to background layers.
--
-- Example:
--   addSpriteForeground "trees", "FrontTrees", -4.0, 0
--   addSpriteForeground "rain",  "RainSheet",   0,   3
--   setForegroundStretch "rain", false   -- tile the rain texture

-- addSpriteForeground pName, pImageSource [, pVX, pVY]
-- Add (or replace) a named foreground layer.  Layers render in the order added.
command addSpriteForeground pName, pImageSource, pVX, pVY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit addSpriteForeground
    local tResolved
    if pImageSource is empty then
        put empty into tResolved
    else
        put spriteResolveImage(pImageSource) into tResolved
    end if
    set the spriteCommand of control tN of this card to "addFg," & pName & "," & tResolved
    if pVX is not empty then
        set the spriteNum1 of control tN of this card to pVX
        set the spriteNum2 of control tN of this card to pVY
        set the spriteCommand of control tN of this card to "setFgLayerVel," & pName
    end if
end addSpriteForeground

-- removeSpriteForeground pName
command removeSpriteForeground pName
    spriteEngSend "removeFg," & pName
end removeSpriteForeground

-- setForegroundVelocity pName, pVX, pVY
command setForegroundVelocity pName, pVX, pVY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setForegroundVelocity
    set the spriteNum1 of control tN of this card to pVX
    set the spriteNum2 of control tN of this card to pVY
    set the spriteCommand of control tN of this card to "setFgLayerVel," & pName
end setForegroundVelocity

-- setForegroundOffset pName, pX, pY
command setForegroundOffset pName, pX, pY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setForegroundOffset
    set the spriteNum1 of control tN of this card to pX
    set the spriteNum2 of control tN of this card to pY
    set the spriteCommand of control tN of this card to "setFgLayerOffset," & pName
end setForegroundOffset

-- setForegroundStretch pName, pBool
-- true  → stretch to fill canvas.  false → tile and scroll (default).
command setForegroundStretch pName, pBool
    if pBool then
        spriteEngSend "setFgLayerStretch," & pName & ",true"
    else
        spriteEngSend "setFgLayerStretch," & pName & ",false"
    end if
end setForegroundStretch

-- setForegroundClip pName, pLeft, pTop, pRight, pBottom
-- Restrict a foreground layer to a rectangular region of the canvas.
-- Example — near trees only in the bottom third of a 400px-tall canvas:
--   setForegroundClip "trees", 0, 260, 800, 400
command setForegroundClip pName, pLeft, pTop, pRight, pBottom
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setForegroundClip
    if pLeft is empty then put 0 into pLeft
    if pTop is empty then put 0 into pTop
    if pRight is empty then put 0 into pRight
    if pBottom is empty then put 0 into pBottom
    set the spriteNum1 of control tN of this card to pLeft
    set the spriteNum2 of control tN of this card to pTop
    set the spriteNum3 of control tN of this card to pRight
    set the spriteNum4 of control tN of this card to pBottom
    set the spriteCommand of control tN of this card to "setFgLayerClip," & pName
end setForegroundClip

-- ---------------------------------------------------------------------------
-- Tilemap (Mario-style level description)
-- ---------------------------------------------------------------------------
-- 1. Register tile images: defineTile "G", "Ground"
-- 2. Mark solid tiles:     defineSolidTile "G", true
-- 3. Set tile size:        setTileSize 32, 32    (default 32×32)
-- 4. Load the map:         loadTilemap pString
-- 5. Track the player:     setCameraFollow "player"
--
-- Map format: a string where each line is a row, each character is a tile.
-- Space and "." = air (nothing drawn).  Any other character = a tile.
-- Characters can't be commas (reserved for the command protocol).
--
-- Example:
--   local tMap
--   put "................................................" & return into tMap
--   put "........PPPP...................................." & return after tMap
--   put "................................................" & return after tMap
--   put "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG" after tMap
--   loadTilemap tMap
-- ---------------------------------------------------------------------------

-- defineTileSheet pImageSource, pCellW, pCellH
-- Load a tile sheet image and specify the pixel dimensions of each cell.
-- After calling this, use defineTile with col/row instead of a file path:
--   defineTileSheet "tileset.png", 16, 16
--   defineTile "G", 2, 0   -- column 2, row 0 (0-based)
--   defineTile "P", 3, 0
command defineTileSheet pImageSource, pCellW, pCellH
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit defineTileSheet
    if pCellW is empty then put 0 into pCellW
    if pCellH is empty then put 0 into pCellH
    set the spriteNum1 of control tN of this card to pCellW
    set the spriteNum2 of control tN of this card to pCellH
    set the spriteCommand of control tN of this card to "setTileSheet," & spriteResolveImage(pImageSource)
end defineTileSheet

-- defineTile pChar, pColOrPath [, pRow]
-- Two modes:
--   File mode  (backward compatible): defineTile "G", "Grass.png"
--   Sheet mode (after defineTileSheet): defineTile "G", 2, 0  -- col=2, row=0
-- Pass empty pColOrPath to unregister a tile (renders as cyan placeholder).
command defineTile pChar, pColOrPath, pRow
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit defineTile
    if pRow is not empty then
        -- Sheet mode: pColOrPath = column (0-based), pRow = row (0-based).
        set the spriteNum1 of control tN of this card to pColOrPath
        set the spriteNum2 of control tN of this card to pRow
        set the spriteCommand of control tN of this card to "setTileCell," & pChar
    else
        -- File mode (backward compatible): pColOrPath is a path or image name.
        local tPath
        if pColOrPath is empty then
            put empty into tPath
        else
            put spriteResolveImage(pColOrPath) into tPath
        end if
        set the spriteCommand of control tN of this card to "defineTile," & pChar & "," & tPath
    end if
end defineTile

-- defineSolidTile pChar, pBool
-- Mark a tile character as solid (blocks sprites) or passable.
-- Tiles are NOT solid by default — call this for ground, walls, platforms.
command defineSolidTile pChar, pBool
    if pBool then
        spriteEngSend "defineSolid," & pChar & ",true"
    else
        spriteEngSend "defineSolid," & pChar & ",false"
    end if
end defineSolidTile

-- setTileSize pWidth, pHeight
-- Pixel dimensions of one tile cell (default 32×32).
command setTileSize pWidth, pHeight
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setTileSize
    set the spriteNum1 of control tN of this card to pWidth
    set the spriteNum2 of control tN of this card to pHeight
    set the spriteCommand of control tN of this card to "setTileSize"
end setTileSize

-- loadTilemap pMapString
-- Parse and load a newline-delimited tile map string.
command loadTilemap pMapString
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit loadTilemap
    set the tileMap of control tN of this card to pMapString
end loadTilemap

-- setCameraPosition pX, pY
-- Manually set the camera's world-pixel position (top-left of the visible area).
command setCameraPosition pX, pY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setCameraPosition
    set the spriteNum1 of control tN of this card to pX
    set the spriteNum2 of control tN of this card to pY
    set the spriteCommand of control tN of this card to "setCameraPos"
end setCameraPosition

-- setCameraFollow pSpriteName
-- Lock the camera to keep a sprite centred in the viewport (clamped to map edges).
-- Pass empty to stop following and return to manual control.
command setCameraFollow pSpriteName
    if pSpriteName is empty then
        spriteEngSend "setCameraFollow,"
    else
        spriteEngSend "setCameraFollow," & pSpriteName
    end if
end setCameraFollow

-- cameraX() / cameraY()
-- Current camera world-pixel position (read-only).
function cameraX
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then return 0
    return the cameraX of control tN of this card
end cameraX

function cameraY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then return 0
    return the cameraY of control tN of this card
end cameraY

-- tileAt(pWorldX, pWorldY)
-- Returns the tile character at the given world-pixel coordinates, or " " for air.
function tileAt pWorldX, pWorldY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then return " "
    set the spriteNum1 of control tN of this card to pWorldX
    set the spriteNum2 of control tN of this card to pWorldY
    set the spriteCommand of control tN of this card to "queryTile"
    return the spriteCommand of control tN of this card
end tileAt

-- isTileSolid(pWorldX, pWorldY)
-- Returns true if the tile at the given world-pixel position is solid.
function isTileSolid pWorldX, pWorldY
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then return false
    set the spriteNum1 of control tN of this card to pWorldX
    set the spriteNum2 of control tN of this card to pWorldY
    set the spriteCommand of control tN of this card to "queryTileSolid"
    return the spriteCommand of control tN of this card is "true"
end isTileSolid

-- spriteOnGround(pName)
-- Returns true if the sprite's bottom edge is resting on a solid tile.
-- Checks three points along the bottom: left, centre, right.
function spriteOnGround pName
    local tInfo
    put spriteInfo(pName) into tInfo
    if tInfo is empty then return false
    local tX, tY, tW, tH
    put item 2 of tInfo into tX
    put item 3 of tInfo into tY
    put item 4 of tInfo into tW
    put item 5 of tInfo into tH
    -- Resolve hitbox (0 = use sprite display dimension).
    local tHX, tHY, tHW, tHH
    put tX + item 10 of tInfo into tHX
    put tY + item 11 of tInfo into tHY
    put item 12 of tInfo into tHW
    put item 13 of tInfo into tHH
    if tHW = 0 then put tW into tHW
    if tHH = 0 then put tH into tHH
    local tFoot
    put tHY + tHH + 1 into tFoot
    if isTileSolid(tHX + 2,        tFoot) then return true
    if isTileSolid(tHX + tHW / 2,  tFoot) then return true
    if isTileSolid(tHX + tHW - 2,  tFoot) then return true
    return false
end spriteOnGround

-- spriteHitsWall(pName, pDir)
-- Returns true if the sprite is touching a solid tile on the given side.
-- pDir = "left" or "right".
function spriteHitsWall pName, pDir
    local tInfo
    put spriteInfo(pName) into tInfo
    if tInfo is empty then return false
    local tX, tY, tW, tH
    put item 2 of tInfo into tX
    put item 3 of tInfo into tY
    put item 4 of tInfo into tW
    put item 5 of tInfo into tH
    local tHX, tHY, tHW, tHH
    put tX + item 10 of tInfo into tHX
    put tY + item 11 of tInfo into tHY
    put item 12 of tInfo into tHW
    put item 13 of tInfo into tHH
    if tHW = 0 then put tW into tHW
    if tHH = 0 then put tH into tHH
    local tCheckX
    if pDir is "left" then
        put tHX - 1 into tCheckX
    else
        put tHX + tHW + 1 into tCheckX
    end if
    if isTileSolid(tCheckX, tHY + tHH / 2)      then return true
    if isTileSolid(tCheckX, tHY + tHH * 3 / 4)  then return true
    return false
end spriteHitsWall

-- spriteHitsCeiling(pName)
-- Returns true if the sprite's top edge is touching a solid tile above it.
function spriteHitsCeiling pName
    local tInfo
    put spriteInfo(pName) into tInfo
    if tInfo is empty then return false
    local tX, tY, tW, tH
    put item 2 of tInfo into tX
    put item 3 of tInfo into tY
    put item 4 of tInfo into tW
    put item 5 of tInfo into tH
    local tHX, tHY, tHW, tHH
    put tX + item 10 of tInfo into tHX
    put tY + item 11 of tInfo into tHY
    put item 12 of tInfo into tHW
    put item 13 of tInfo into tHH
    if tHW = 0 then put tW into tHW
    if tHH = 0 then put tH into tHH
    local tHead
    put tHY - 1 into tHead
    if isTileSolid(tHX + 2,        tHead) then return true
    if isTileSolid(tHX + tHW / 2,  tHead) then return true
    if isTileSolid(tHX + tHW - 2,  tHead) then return true
    return false
end spriteHitsCeiling

-- spriteVX(pName) / spriteVY(pName)
-- Read the current velocity components of a sprite.
function spriteVX pName
    return item 6 of spriteInfo(pName)
end spriteVX

function spriteVY pName
    return item 7 of spriteInfo(pName)
end spriteVY


-- ---------------------------------------------------------------------------
-- Collision resolution helpers
-- ---------------------------------------------------------------------------
-- These snap sprites to tile boundaries after a collision is detected.
-- The tile dimensions you pass must match what you gave to setTileSize.
--
-- Why snap AND zero velocity?
--   Zeroing velocity stops future movement but the sprite may already be a
--   few pixels inside the tile (if it was moving fast).  Snapping corrects
--   the position so it sits flush against the tile face.
--
-- Cap your fall speed to less than the tile height (e.g. kMaxFall = 10 with
--   kTileH = 32) to avoid tunnelling through thin platforms at high speed.
--
-- EXAMPLE spriteTick physics loop:
-- ---------------------------------------------------------------------------
--   local gPlayerVY   -- track vertical velocity yourself so you can cap it
--
--   on spriteTick
--      local kTileH, kTileW, kGravity, kMaxFall
--      put 32   into kTileH
--      put 32   into kTileW
--      put 0.5  into kGravity
--      put 10   into kMaxFall
--
--      -- Ground / gravity
--      if spriteOnGround("player") then
--         snapSpriteToGround "player", kTileH
--         put 0 into gPlayerVY
--      else
--         add kGravity to gPlayerVY
--         if gPlayerVY > kMaxFall then put kMaxFall into gPlayerVY
--      end if
--
--      -- Ceiling (e.g. jump hits an overhead block)
--      if spriteHitsCeiling("player") and gPlayerVY < 0 then
--         put 0 into gPlayerVY
--      end if
--
--      -- Walls
--      if spriteHitsWall("player", "right") and spriteVX("player") > 0 then
--         snapSpriteFromWall "player", "right", kTileW
--         setSpriteVelocity "player", 0, gPlayerVY
--         exit spriteTick
--      end if
--      if spriteHitsWall("player", "left") and spriteVX("player") < 0 then
--         snapSpriteFromWall "player", "left", kTileW
--         setSpriteVelocity "player", 0, gPlayerVY
--         exit spriteTick
--      end if
--
--      -- Apply the resolved vertical velocity (horizontal set by key handlers)
--      setSpriteVelocity "player", spriteVX("player"), gPlayerVY
--   end spriteTick
-- ---------------------------------------------------------------------------

-- snapSpriteToGround pName, pTileH
-- Push a sprite upward so its bottom edge sits exactly on the tile boundary it
-- landed on.  Call this alongside zeroing vy whenever spriteOnGround is true.
command snapSpriteToGround pName, pTileH
    local tInfo
    put spriteInfo(pName) into tInfo
    if tInfo is empty then exit snapSpriteToGround
    local tX, tY, tW, tH
    put item 2 of tInfo into tX
    put item 3 of tInfo into tY
    put item 4 of tInfo into tW
    put item 5 of tInfo into tH
    local tHOffY, tHH
    put item 11 of tInfo into tHOffY
    put item 13 of tInfo into tHH
    if tHH = 0 then put tH into tHH
    -- Snap hitbox bottom to tile boundary, then derive sprite Y from that.
    local tHitBottomY, tTileRow, tSnappedY
    put tY + tHOffY + tHH into tHitBottomY
    put (tHitBottomY + 1) DIV pTileH into tTileRow
    put tTileRow * pTileH - tHOffY - tHH into tSnappedY
    setSpritePosition pName, tX, tSnappedY
end snapSpriteToGround

-- snapSpriteFromWall pName, pDir, pTileW
-- Push a sprite horizontally so its edge is flush with the wall it hit.
-- pDir = "right" (moved right into a wall) or "left" (moved left into a wall).
command snapSpriteFromWall pName, pDir, pTileW
    local tInfo
    put spriteInfo(pName) into tInfo
    if tInfo is empty then exit snapSpriteFromWall
    local tX, tY, tW, tH
    put item 2 of tInfo into tX
    put item 3 of tInfo into tY
    put item 4 of tInfo into tW
    put item 5 of tInfo into tH
    local tHOffX, tHW
    put item 10 of tInfo into tHOffX
    put item 12 of tInfo into tHW
    if tHW = 0 then put tW into tHW
    local tSnappedX
    if pDir is "right" then
        -- Probe was at hitbox right + 1; snap hitbox right to tile left face,
        -- then derive sprite X from the hitbox offset.
        put (((tX + tHOffX + tHW + 1) DIV pTileW) * pTileW) - tHW - tHOffX into tSnappedX
    else
        -- Probe was at hitbox left - 1; snap hitbox left to tile right face.
        put (((tX + tHOffX - 1) DIV pTileW) + 1) * pTileW - tHOffX into tSnappedX
    end if
    setSpritePosition pName, tSnappedX, tY
end snapSpriteFromWall


-- setSpriteHitbox pName, pOffX, pOffY, pW, pH
-- Set a custom collision hitbox, smaller than the sprite's display rect.
-- pOffX, pOffY: offset from sprite top-left corner in pixels.
-- pW, pH: hitbox width and height in pixels.
-- Pass 0,0,0,0 to reset to the full sprite display rect (the default).
-- Example — a 30x56 box centred horizontally on an 80x64 sprite:
--   setSpriteHitbox "player", 25, 8, 30, 56
command setSpriteHitbox pName, pOffX, pOffY, pW, pH
    local tN
    put spriteCanvasNum() into tN
    if tN is 0 then exit setSpriteHitbox
    set the spriteNum1 of control tN of this card to pOffX
    set the spriteNum2 of control tN of this card to pOffY
    set the spriteNum3 of control tN of this card to pW
    set the spriteNum4 of control tN of this card to pH
    set the spriteCommand of control tN of this card to "setHitbox," & pName
end setSpriteHitbox

-- setSpriteFlipX pName, pBool
-- Flip a sprite horizontally. Pass true to mirror, false to restore.
-- Example: setSpriteFlipX "player", true
command setSpriteFlipX pName, pBool
    if pBool then
        spriteEngSend "setFlipX," & pName & ",true"
    else
        spriteEngSend "setFlipX," & pName & ",false"
    end if
end setSpriteFlipX

-- setSpriteBackground pR, pG, pB
-- Set the canvas background colour (0‚Äì1 float components).
-- Example: setSpriteBackground 0.1, 0.1, 0.2  -- dark navy
command setSpriteBackground pR, pG, pB
    local tN
    put spriteCanvasNum() into tN
    if tN > 0 then
        set the backgroundColor of control tN of this card to pR & "," & pG & "," & pB
    end if
end setSpriteBackground
