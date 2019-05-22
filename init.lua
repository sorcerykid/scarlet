--------------------------------------------------------
-- Minetest :: Scarlet Mod (scarlet)
--
-- See README.txt for licensing and release notes.
-- Copyright (c) 2019, Leslie E. Krause
--------------------------------------------------------

scarlet = { }

------------------------
-- UnitConversion Class
------------------------

function UnitConversion( screen_dpi, gui_scaling, has_padding )
	local self = { }
        local image_size = 0.55 * ( screen_dpi or 72 ) * ( gui_scaling or 1 )

	-- calculate the dot pitch as images per pixel and cells per pixel
	-- using the "black magic" algorithm from guiFormSpecMenu.cpp

	self.dot_pitch = {
		-- imgsize (images per pixel)
		ix = 1 / image_size,
		iy = 1 / image_size,
		-- spacing (cells per pixel)
                x = 1 / image_size * 4 / 5,
                y = 1 / image_size * 13 / 15
	}

	-- padding width and height in cell units
	-- original formula: image_size * 3.0 / 8
	self.padding_width = has_padding and 0.0 or 3 / 10
	self.padding_height = has_padding and 0.0 or 13 / 40

	-- nominal button height in cell units
	-- NB: this is 2x the value of m_button_height used internally!
	-- original formula: image_size * 15.0 / 13 * 0.35
	self.button_height = 0.7

	-- cell margin width and height in cell units
	-- original formula: vx * spacing.x - ( spacing.x - imgsize.x )
	self.cell_margin_width = 1 / 5
	self.cell_margin_height = 2 / 15

	self.units = ( function ( )
		-- cell size measurements
	       	local factors = {
			d = { x = 1 / 39.6 * 4 / 5, y = 1 / 39.6 * 13 / 15 },
               		i = { x = 4 / 5, y = 13 / 15 },			-- imgsize
	        	c = { x = 1, y = 1 },				-- spacing (unity)
       			b = { y = self.button_height },			-- 2 x m_button_height
	        }
       		local function get_x( v, u, dot_pitch )
			return not factors[ u ] and math.floor( v ) * self.dot_pitch.x or v * factors[ u ].x
	        end
       		local function get_y( v, u, dot_pitch )
			return not factors[ u ] and math.floor( v ) * self.dot_pitch.y or v * factors[ u ].y
	        end
		return { get_x = get_x, get_y = get_y }
	end )( )

	self.iunits = ( function ( )
		-- image size measurements
		local factors = {
			d = { x = 1 / 39.6, y = 1 / 39.6 },
			i = { x = 1, y = 1 },				-- imgsize (unity)
			c = { x = 5 / 4, y = 15 / 13 },			-- spacing
			b = { y = self.button_height * 15 / 13 },	-- 2 x m_button_height
		}
       		local function get_x( v, u )
			return not factors[ u ] and math.floor( v ) * self.dot_pitch.ix or v * factors[ u ].x
	        end
       		local function get_y( v, u )
			return not factors[ u ] and math.floor( v ) * self.dot_pitch.iy or v * factors[ u ].y
	        end
		return { get_x = get_x, get_y = get_y }
	end )( )

	return self
end

---------------------------
-- RuntimeTranslator Class
---------------------------

function RuntimeTranslator( screen_dpi, gui_scaling, has_padding )

	local self = UnitConversion( screen_dpi, gui_scaling, has_padding )	-- extend the base class

	self.margins = { { width = 0.0, height = 0.0 } }

	self.insert_margin = function ( width, height )
		table.insert( self.margins, 1,
			{ width = width + self.margins[ 1 ].width, height = height + self.margins[ 1 ].height }
		)
	end

	self.remove_margin = function ( )
		if #self.margins > 1 then
			table.remove( self.margins, 1 )
		end
	end

	self.get_pos = function ( pos_value, pos_units, offsets )
		if pos_value then
			local pos_x, u1, pos_y, u2 = string.match( pos_value, "^(-?[0-9.]+)([icpd]?),(-?[0-9.]+)([icpdb]?)$" )

			if not pos_x then return end

			return string.format( "%0.3f,%0.3f",
				pos_units.get_x( pos_x, u1 ) + offsets[ 1 ] + self.margins[ 1 ].width,
				pos_units.get_y( pos_y, u2 ) + offsets[ 2 ] + self.margins[ 1 ].height
			)
		end
	end

	self.get_pos_and_dim_x = function ( pos_value, dim_value, pos_units, dim_units, offsets )
		if pos_value and dim_value then
			local pos_x, u1, pos_y, u2 = string.match( pos_value, "^(-?[0-9.]+)([icpd]?),(-?[0-9.]+)([icpdb]?)$" )
			local dim_x, u3 = string.match( dim_value, "^([0-9.]+)([iscp]?)$" )

			if not pos_x or not dim_x then return end

			if u3 == "s" then
				u3 = "i"
				offsets[ 3 ] = offsets[ 3 ] + ( dim_x % 1 == 0 and dim_x - 1 or math.floor( dim_x ) ) * self.cell_margin_width
			end

			return string.format( "%0.3f,%0.3f;%0.3f,0.000",
				pos_units.get_x( pos_x, u1 ) + offsets[ 1 ] + self.margins[ 1 ].width,
				pos_units.get_y( pos_y, u2 ) + offsets[ 2 ] + self.margins[ 1 ].height,
				dim_units.get_x( dim_x, u3 ) + offsets[ 3 ]
			)
		end
	end

	self.get_pos_and_dim = function ( pos_value, dim_value, pos_units, dim_units, offsets )
		if pos_value and dim_value then
			local pos_x, u1, pos_y, u2 = string.match( pos_value, "^(-?[0-9.]+)([icpd]?),(-?[0-9.]+)([icpdb]?)$" )
			local dim_x, u3, dim_y, u4 = string.match( dim_value, "^([0-9.]+)([iscpd]?),([0-9.]+)([iscpdb]?)$" )

			if not pos_x or not dim_x then return end

			if u3 == "s" then
				u3 = "i"
				offsets[ 3 ] = offsets[ 3 ] + ( dim_x % 1 == 0 and dim_x - 1 or math.floor( dim_x ) ) * self.cell_margin_width
			end
			if u4 == "s" then
				u4 = "i"
				offsets[ 4 ] = offsets[ 4 ] + ( dim_y % 1 == 0 and dim_y - 1 or math.floor( dim_y ) ) * self.cell_margin_height
			end

			return string.format( "%0.3f,%0.3f;%0.3f,%0.3f",
				pos_units.get_x( pos_x, u1 ) + offsets[ 1 ] + self.margins[ 1 ].width,
				pos_units.get_y( pos_y, u2 ) + offsets[ 2 ] + self.margins[ 1 ].height,
				dim_units.get_x( dim_x, u3 ) + offsets[ 3 ],
				dim_units.get_y( dim_y, u4 ) + offsets[ 4 ]
			)
		end
	end

	return self
end

------------------------------
-- Generic Element Subclasses
------------------------------

local function element( name, params )
	return name .. "[" .. table.concat( params, ";" ) .. "]"
end

local function ElemPos( pos_units, length )
	return function ( tx, name, params )
		local pos = tx.get_pos( params[ 1 ], pos_units, {
			-tx.padding_width,
			-tx.padding_height
		} )
		assert( pos and #params == length, "Cannot parse formspec element " .. name .. "[]" )
		return element( name, { pos, unpack( params, 2 ) } )
	end
end

local function ElemPosAndDim( pos_units, dim_units, length, is_unlimited )
	return function ( tx, name, params )
		local pos_and_dim = tx.get_pos_and_dim( params[ 1 ], params[ 2 ], pos_units, dim_units, {
			-tx.padding_width,
			-tx.padding_height,
			0,
			0
		} )
		assert( pos_and_dim and ( #params == length or is_unlimited and #params > length ), "Cannot parse formspec element " .. name .. "[]" )
		return element( name, { pos_and_dim, unpack( params, 3 ) } )
	end
end

local function ElemPosAndDimX( pos_units, dim_units, length, is_unlimited )
	return function ( tx, name, params )
		local pos_and_dim_x = tx.get_pos_and_dim_x( params[ 1 ], params[ 2 ], pos_units, dim_units, {
			-tx.padding_width,
			-tx.padding_height,
			0
		} )
		assert( pos_and_dim_x and ( #params == length or is_unlimited and #params > length ), "Cannot parse formspec element " .. name .. "[]" )
		return element( name, { pos_and_dim_x, unpack( params, 3 ) } )
	end
end

------------------------------
-- Special Element Subclasses 
------------------------------

local function SizeElement( )
	local pattern = "^(%d+)([iscp]?),(%d+)([iscpb]?)$"
	local replace = "%0.3f,%0.3f,true"

	return function ( tx, name, params )
		local dim, count = string.gsub( params[ 1 ], pattern, function ( dim_x, u1, dim_y, u2 )
			return string.format( replace,
				tx.units.get_x( dim_x, u1 ),
				tx.units.get_y( dim_y, u2 )
			)
		end )
		assert( count == 1, "Cannot parse formspec element size[]" )
		return element( "size", { dim } )
	end
end

-- list[<inventory_location>;<list_name>;<x>,<y>;<colums>;<rows>]

local function ListElement( )
	local pattern = "^(%d+)([icp]?),(%d+)([icpb]?)$"
	local replace = "%0.3f,%0.3f"

	return function ( tx, name, params )
		local pos = tx.get_pos( params[ 3 ], tx.units, {
			-tx.padding_width,
			-tx.padding_height,
		} )
		assert( pos and ( #params == 4 or #params == 5 ), "Cannot parse formspec element list[]" )
		return element( "list", { params[ 1 ], params[ 2 ], pos, unpack( params, 4 ) } )
	end
end

-- margin[]
-- margin[<x>,<y>]

local function MarginElement( )
	local pattern = "^(-?[0-9.]+)([icpd]?),(-?[0-9.]+)([icpdb]?)$"

	return function ( tx, name, params )
		if #params == 0 then
			tx.insert_margin( tx.padding_width, tx.padding_height )
		else
			local pos_x, u1, pos_y, u2 = string.match( params[ 1 ], pattern )
			assert( pos_x and #params == 1, "Cannot parse formspec element margin[]" )
			tx.insert_margin( tx.units.get_x( pos_x, u1 ), tx.units.get_y( pos_y, u2 ) )
		end
		return ""	-- remove virtual element
	end
end

-- margin_end[]

local function MarginEndElement( )
	return function ( tx, name, params )
		assert( #params == 0, "Cannot parse formspec element container_end[]" )
		tx.remove_margin( )
		return ""	-- remove virtual element
	end
end

-- background[<w>,<h>;<texture name>]

local function BackgroundElement( )
	local pattern = "^(-?%d+),(-?%d+)$"
	local replace = "%d,%d;0,0"

	return function ( tx, name, params )
		local dim, count = string.gsub( params[ 1 ], pattern, function ( pos_x, pos_y )
			return string.format( replace, -pos_x, -pos_y )
		end )
		assert( count == 1, "Cannot parse formspec element background[]" )
		return element( "background", { dim, params[ 2 ], "true" } )
	end
end

-- bgimage[<x>,<y>;<w>,<h>;<texture name>]

local function BgImageElement( )
	return function ( tx, name, params )
		-- original formula: vx * spacing.x - ( spacing.x - imgsize.x ) / 2
		local pos_offset_x = 0.5 * 1 / 5
		local pos_offset_y = 0.5 * 2 / 15

		local pos_and_dim = tx.get_pos_and_dim( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			-tx.padding_width + pos_offset_x,
			-tx.padding_height + pos_offset_y,
			0,
			0
		} )
		assert( pos_and_dim and #params == 3, "Cannot parse formspec element bgimage[]" )
		return element( "background", { pos_and_dim, params[ 3 ], "false" } )
	end
end

-- label[<x>,<y>;<label>]
-- vertlabel[<x>,<y>;<label>]

local function LabelElement( is_vertical )
	return function ( tx, name, params )
		-- original formula: ( vy + 7 / 30 ) * spacing.y - m_button_height
		local pos_offset_y = -7 / 30 + tx.button_height / 2

		local pos = tx.get_pos( params[ 1 ], tx.units, {
			-tx.padding_width,
			-tx.padding_height + pos_offset_y,
		} )
		assert( pos and #params == 2, "Cannot parse formspec element " .. name .. "[]" )
		return element( is_vertical and "vertlabel" or "label", { pos, params[ 2 ] } )
	end
end

-- checkbox[<x>,<y>;<w>;<name>;<label>]

local function CheckboxElement( )
	return function ( tx, name, params )
		-- original formula: vy * spacing.y + ( imgsize.y / 2 ) - m_button_height
		local pos_offset_y = -13 / 30 + tx.button_height / 2

		local pos = tx.get_pos( params[ 1 ], tx.units, {
			-tx.padding_width,
			-tx.padding_height + pos_offset_y,
		} )
		assert( pos and #params == 4, "Cannot parse formspec element checkbox[]" )
		return element( "checkbox", { pos, unpack( params, 3 ) } )
	end
end

-- button[<x>,<y>;<w>;<name>;<label>]

local function ButtonElement( )
	return function ( tx, name, params )
		local pos_and_dim = tx.get_pos_and_dim( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			-tx.padding_width,
			-tx.padding_height,
			tx.cell_margin_width,
			tx.cell_margin_height,
		} )
		assert( pos_and_dim and #params == 4, "Cannot parse formspec element " .. name .. "[]" )
		return element( "image_" .. name, { pos_and_dim, "", unpack( params, 3 ) } )
	end
end

-- image_button[<x>,<y>;<w>;<name>;<texture_name>;<label>]

local function ImageButtonElement( )
	return function ( tx, name, params )
		local pos_and_dim = tx.get_pos_and_dim( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			-tx.padding_width,
			-tx.padding_height,
			tx.cell_margin_width,
			tx.cell_margin_height,
		} )
		assert( pos_and_dim and ( #params == 5 or #params == 8 ), "Cannot parse formspec element " .. name .. "[]" )
		return element( name, { pos_and_dim, params[ 4 ], params[ 3 ], unpack( params, 5 ) } )
	end
end

-- item_image_button[<x>,<y>;<w>,<h>;<item name>;<name>;<label>]

local function ItemImageButtonElement( )
	return function ( tx, name, params )
		local pos_and_dim = tx.get_pos_and_dim( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			-tx.padding_width,
			-tx.padding_height,
			tx.cell_margin_width,
			tx.cell_margin_height,
		} )
		assert( pos_and_dim and #params == 5, "Cannot parse formspec element item_image_button[]" )
		return element( "item_image_button", { pos_and_dim, params[ 4 ], params[ 3 ], params[ 5 ] } )
	end
end

-- textlist[<x>,<y>;<w>,<h>;<name>;...]

local function TextListElement( )
	return function ( tx, name, params )
		local pos_and_dim = tx.get_pos_and_dim( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			-tx.padding_width,
			-tx.padding_height,
			0,
			0,
		} )
		assert( pos_and_dim and ( #params == 4 or #params == 5 ), "Cannot parse formspec element textlist[]" )
		return element( "textlist", { pos_and_dim, unpack( params, 3 ) } )
	end
end

-- dropdown[<x>,<y>;<w>,<h>;<name>;...]

local function DropdownElement( )
	return function ( tx, name, params )
		local pos_and_dim_x = tx.get_pos_and_dim_x( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			-tx.padding_width,
			-tx.padding_height,
			0,
			0,
		} )
		assert( pos_and_dim_x and #params == 5, "Cannot parse formspec element dropdown[]" )
		return element( "dropdown", { pos_and_dim_x, unpack( params, 3 ) } )
	end
end

-- pwdfield[<x>,<y>;<w>;<name>]

local function PwdFieldElement( )
	return function ( tx, name, params )
		local pos_and_dim_x = tx.get_pos_and_dim_x( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			0,
			tx.button_height / 2,
			tx.cell_margin_width,
		} )
		assert( pos_and_dim_x, #params == 3, "Cannot parse formspec element pwdfield[]" )
		return element( "pwdfield", { pos_and_dim_x, params[ 3 ], "" } )
	end
end

-- field[<x>,<y>;<w>;<name>;<default>]

local function FieldElement( )
	return function ( tx, name, params )
		local pos_and_dim_x = tx.get_pos_and_dim_x( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			0,
			tx.button_height / 2,
			tx.cell_margin_width,
		} )
		assert( pos_and_dim_x and #params == 4, "Cannot parse formspec element field[]" )
		return element( "field", { pos_and_dim_x, params[ 3 ], "", params[ 4 ] } )
	end
end

-- caption[<x>,<y>;<w>,<h>;<caption>]

local function CaptionElement( )
	return function ( tx, name, params )
		local pos_and_dim = tx.get_pos_and_dim( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			0,
			-tx.button_height / 2,
			tx.cell_margin_width,
			tx.cell_margin_height + tx.button_height / 2
		} )
		assert( pos_and_dim and #params == 3, "Cannot parse formspec element caption[]" )
		return element( "textarea", { pos_and_dim, "", params[ 3 ], "" } )
	end
end

-- textarea[<x>,<y>;<w>,<h>;<name>;<default>]

local function TextAreaElement( )
	return function ( tx, name, params )
		local pos_and_dim = tx.get_pos_and_dim( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			0,
			-tx.button_height / 2,
			tx.cell_margin_width,
			tx.cell_margin_height + tx.button_height / 2
		} )
		assert( pos_and_dim and #params == 4, "Cannot parse formspec element textarea[]" )
		return element( "textarea", { pos_and_dim, params[ 3 ], "", params[ 4 ] } )
	end
end

-- horz_scrollbar[<x>,<y>;<w>,<h>;<name>;<value>]
-- vert_scrollbar[<x>,<y>;<w>,<h>;<name>;<value>]

local function ScrollbarElement( orientation )
	return function ( tx, name, params )
		local pos_and_dim = tx.get_pos_and_dim( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			-tx.padding_width,
			-tx.padding_height,
			0,
			0
		} )
		assert( pos_and_dim and #params == 4, "Cannot parse formspec element " .. name .. "[]" )
		return element( "scrollbar", { pos_and_dim, orientation, unpack( params, 3 ) } )
	end
end

-- area_tooltip[<x>,<y>;<w>,<h>;<name>;<tooltip_text>]

local function AreaTooltipElement( )
	return function ( tx, name, params )
		local pos_and_dim = tx.get_pos_and_dim( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			-tx.padding_width,
			-tx.padding_height,
			0,
			0
		} )
		assert( pos_and_dim and #params >= 3, "Cannot parse formspec element area_tooltip[]" )
		return element( "tooltip", { pos_and_dim, unpack( params, 3 ) } )
	end
end

-- tabheader[<x>,<y>;<w>,<h>;<name>;<tooltip_text>]

local function TabHeaderElement( )
	return function ( tx, name, params )
		local pos = tx.get_pos( params[ 1 ], tx.units, {
			0,
			0
		} )
		assert( pos and ( #params == 4 or #params == 6 ), "Cannot parse formspec element tabheader[]" )
		return element( "tabheader", { pos, unpack( params, 2 ) } )
	end
end

-------------------------
-- Translation Interface
-------------------------

scarlet.translate = function ( fs, screen_dpi, gui_scaling )

	local tx = RuntimeTranslator( screen_dpi, gui_scaling, false )

	local element_parsers = {
		size			= SizeElement( ),
		list			= ListElement( ),
		background		= BackgroundElement( ),
		box			= ElemPosAndDim( tx.units, tx.units, 3, false ),
		button			= ButtonElement( ),
		button_exit		= ButtonElement( ),
		image_button		= ImageButtonElement( ),
		image_button_exit	= ImageButtonElement( ),
		bgimage			= BgImageElement( ),
		label			= LabelElement( false ),
		vertlabel		= LabelElement( true ),
		checkbox		= CheckboxElement( ),
		pwdfield		= PwdFieldElement( ),
		item_image_button	= ItemImageButtonElement( ),
		image			= ElemPosAndDim( tx.units, tx.iunits, 3, false ),
		item_image		= ElemPosAndDim( tx.units, tx.iunits, 3, false ),
		field			= FieldElement( ),
		dropdown		= DropdownElement( ),
		textlist		= TextListElement( ),
		vert_scrollbar		= ScrollbarElement( "vertical" ),
		horz_scrollbar		= ScrollbarElement( "horizontal" ),
		table			= ElemPosAndDim( tx.units, tx.units, 5, false ),
		textarea		= TextAreaElement( ),
		caption			= CaptionElement( ),
		area_tooltip		= AreaTooltipElement( ),		-- not added until 5.0 (https://github.com/minetest/minetest/pull/7469)
		container		= ElemPos( tx.units, 1 ),		-- not fixed until 5.0 (https://github.com/minetest/minetest/pull/7497)
		margin			= MarginElement( ),			-- emulation of container[] element
		margin_end		= MarginEndElement( ),
		tabheader		= TabHeaderElement( ),
	}

	fs = string.gsub( fs, "([a-z_]+)%[(.-)%]", function( name, parts )
		local parser = element_parsers[ name ]
		if parser then
			local res = parser( tx, name, parts == "" and { } or string.split( parts, ";", true ) )
			return res
		end
	end )

--	minetest.debug( "ACTION", "Result:" .. fs )
	return fs
end

scarlet.translate_96dpi = function ( fs )
	return scarlet.translate( fs, 96, 1 )
end

scarlet.translate_72dpi = function ( fs )
	return scarlet.translate( fs, 72, 1 )
end
