--------------------------------------------------------
-- Minetest :: Scarlet Mod (scarlet)
--
-- See README.txt for licensing and release notes.
-- Copyright (c) 2019, Leslie E. Krause
--------------------------------------------------------

scarlet = { }

--------------------------
-- Local Helper Functions
--------------------------

local function element( name, params )
	return name .. "[" .. table.concat( params, ";" ) .. "]"
end

local function is_match( text, glob )
	_ = { string.match( text, glob ) }
	return #_ > 0
end

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

	-- button height in cell units
	-- NB: this is 2x the value of m_btn_height used internally!
	-- original formula: image_size * 15.0 / 13 * 0.35
	self.button_height = 0.7

	-- cell margin width and height in cell units
	-- original formula: vx * spacing.x - ( spacing.x - imgsize.x )
	self.cell_margin_width = 1 / 5
	self.cell_margin_height = 2 / 15

	-- point width and height in cell units
	self.point_width = 1 / 39.6 * 4 / 5
	self.point_height = 1 / 39.6 * 13 / 15

	self.units = ( function ( )
		-- cell size measurements
		local factors = {
			p = { x = self.point_width, y = self.point_height },
			i = { x = 4 / 5, y = 13 / 15 },			-- imgsize
			c = { x = 1, y = 1 },				-- spacing (unity)
			b = { y = self.button_height },			-- 2 x m_btn_height
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
			p = { x = 1 / 39.6, y = 1 / 39.6 },
			i = { x = 1, y = 1 },				-- imgsize (unity)
			c = { x = 5 / 4, y = 15 / 13 },			-- spacing
			b = { y = self.button_height * 15 / 13 },	-- 2 x m_btn_height
		}
		local function get_x( v, u )
			return not factors[ u ] and math.floor( v ) * self.dot_pitch.ix or v * factors[ u ].x
		end
		local function get_y( v, u )
			return not factors[ u ] and math.floor( v ) * self.dot_pitch.iy or v * factors[ u ].y
		end
		return { get_x = get_x, get_y = get_y }
	end )( )

	self.evaluate = function ( axis, expr, old_res )
		local res = 0.0
		local glob, vars, to_val

		if axis == "x" then
			glob = "^([-+][0-9.]+)([cpdi])$"
			vars = { P = self.padding_width, S = self.cell_margin_width, R = old_res or 0.0 }
			to_val = self.units.get_x
		elseif axis == "y" then
			glob = "^([-+][0-9.]+)([cpdib])$"
			vars = { P = self.padding_height, S = self.cell_margin_height, B = self.button_height, R = old_res or 0.0 }
			to_val = self.units.get_y
		else
			return
		end

		local pos1 = 1

		if not string.match( expr, "^[-+]" ) then expr = "+" .. expr end

		while pos1 do
			local pos2 = string.find( expr, "[-+]", pos1 + 1 )
			local token = string.sub( expr, pos1, pos2 and pos2 - 1 )

			if is_match( token, "^([-+])%$([A-Z])$" ) and vars[ _[ 2 ] ] then
				res = res + tonumber( _[ 1 ] .. vars[ _[ 2 ] ] )
			elseif is_match( token, glob ) then
				res = res + to_val( tonumber( _[ 1 ] ), _[ 2 ] )
			else
				return
			end

			pos1 = pos2
		end

		return res
	end

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

	self.get_pos_raw = function ( pos_value )
		if pos_value then
			return string.match( pos_value, "^(-?[0-9.]+)([icpd]?),(-?[0-9.]+)([icpdb]?)$" )
		end
	end

	self.get_dim_raw = function ( dim_value )
		if dim_value then
			return string.match( dim_value, "^([0-9.]+)([iscpd]?),([0-9.]+)([iscpdb]?)$" )
		end
	end

	return self
end

------------------------------
-- Generic Element Subclasses
------------------------------

local function ElemPos( pos_units, length, has_padding )
	return function ( tx, name, params )
		local pos = tx.get_pos( params[ 1 ], pos_units, {
			has_padding and -tx.padding_width or 0,
			has_padding and -tx.padding_height or 0
		} )
		assert( pos and #params == length, "Cannot parse formspec element " .. name .. "[]" )
		return element( name, { pos, unpack( params, 2 ) } )
	end
end

local function ElemPosAndDim( pos_units, dim_units, length, has_padding )
	return function ( tx, name, params )
		local pos_and_dim = tx.get_pos_and_dim( params[ 1 ], params[ 2 ], pos_units, dim_units, {
			has_padding and -tx.padding_width or 0,
			has_padding and -tx.padding_height or 0,
			0,
			0
		} )
		assert( pos_and_dim and #params == length, "Cannot parse formspec element " .. name .. "[]" )
		return element( name, { pos_and_dim, unpack( params, 3 ) } )
	end
end

local function ElemPosAndDimX( pos_units, dim_units, length, has_padding )
	return function ( tx, name, params )
		local pos_and_dim_x = tx.get_pos_and_dim_x( params[ 1 ], params[ 2 ], pos_units, dim_units, {
			has_padding and -tx.padding_width or 0,
			has_padding and -tx.padding_height or 0,
			0
		} )
		assert( pos_and_dim_x and #params == length, "Cannot parse formspec element " .. name .. "[]" )
		return element( name, { pos_and_dim_x, unpack( params, 3 ) } )
	end
end

------------------------------
-- Special Element Subclasses 
------------------------------

-- size[<w>,<h>]
-- size[<w>,<h>;<x>,<y>]

local function SizeElement( )
	return function ( tx, name, params )
		local pos_offset_x, pos_offset_y
		local dim_x, u1, dim_y, u2 = tx.get_dim_raw( params[ 1 ] )
		local pos_x, u3, pos_y, u4 = tx.get_pos_raw( params[ 2 ] )

		assert( #params == 1 and dim_x or #params == 2 and dim_x and ( params[ 2 ] == "" or pos_x ), "Cannot parse formspec element size[]" )

		if u1 == "s" then
			u1 = "c"
			dim_x = dim_x - tx.cell_margin_width
		end
		if u2 == "s" then
			u2 = "c"
			dim_y = dim_y - tx.cell_margin_height
		end

		if not pos_x then
			pos_offset_x = tx.padding_width
			pos_offset_y = tx.padding_height
		else
			pos_offset_x = tx.units.get_x( pos_x, u3 )
			pos_offset_y = tx.units.get_y( pos_y, u4 )
		end
		tx.insert_margin( pos_offset_x, pos_offset_y )

		-- original formulas:
		-- padding.x * 2 + spacing.x * ( vx - 1.0 ) + imgsize.x
		-- padding.y * 2 + spacing.y * ( vy - 1.0 ) + imgsize.y + m_btn_height * 2.0 / 3.0
		local dim =  string.format( "%0.3f,%0.3f",
			tx.units.get_x( dim_x, u1 ) + 2 * pos_offset_x + 1 - tx.padding_width * 2 - 4 / 5,
			tx.units.get_y( dim_y, u2 ) + 2 * pos_offset_y + 1 - tx.padding_height * 2 - 13 / 15 - tx.button_height / 3
		)
		return element( "size", { dim } )
	end
end

-- list[<inventory_location>;<list_name>;<x>,<y>;<colums>;<rows>]

local function ListElement( )
	local pattern = "^(-?[0-9.]+)([icpd]?),(-?[0-9.]+)([icpdb]?)$"
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

-- checkbox[<x>,<y>;<name>;<label>;<selected>]

local function CheckboxElement( )
	return function ( tx, name, params )
		-- original formula: vy * spacing.y + ( imgsize.y / 2 ) - m_button_height
		local pos_offset_y = -13 / 30 + tx.button_height / 2

		local pos = tx.get_pos( params[ 1 ], tx.units, {
			-tx.padding_width,
			-tx.padding_height + pos_offset_y,
		} )
		assert( pos and #params == 4, "Cannot parse formspec element checkbox[]" )
		return element( "checkbox", { pos, unpack( params, 2 ) } )
	end
end

-- button[<x>,<y>;<w>,<h>;<name>;<label>]

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

-- image_button[<x>,<y>;<w>,<h>;<name>;<texture_name>;<label>]

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

-- textlist[<x>,<y>;<w>,<h>;<name>;<item_1>...;<selected_idx>]

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

-- dropdown[<x>,<y>;<w>;<name>;<item_1>...;<selected_idx>]

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
	local use_legacy_render = minetest.is_player == nil

	return function ( tx, name, params )
		local pos_and_dim = tx.get_pos_and_dim( params[ 1 ], params[ 2 ], tx.units, tx.units, {
			use_legacy_render and 0 or -tx.point_width * 3,
			-tx.button_height / 2,
			use_legacy_render and tx.cell_margin_width or tx.cell_margin_width + tx.point_width * 6,
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
		assert( pos_and_dim and ( #params == 3 or #params == 5 ), "Cannot parse formspec element area_tooltip[]" )
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
		box			= ElemPosAndDim( tx.units, tx.units, 3, true ),
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
		image			= ElemPosAndDim( tx.units, tx.iunits, 3, true ),
		item_image		= ElemPosAndDim( tx.units, tx.iunits, 3, true ),
		field			= FieldElement( ),
		dropdown		= DropdownElement( ),
		textlist		= TextListElement( ),
		vert_scrollbar		= ScrollbarElement( "vertical" ),
		horz_scrollbar		= ScrollbarElement( "horizontal" ),
		table			= ElemPosAndDim( tx.units, tx.units, 5, true ),
		textarea		= TextAreaElement( ),
		caption			= CaptionElement( ),
		area_tooltip		= AreaTooltipElement( ),		-- not added until 5.0 (https://github.com/minetest/minetest/pull/7469)
		container		= ElemPos( tx.units, 1, false ),	-- not fixed until 5.0 (https://github.com/minetest/minetest/pull/7497)
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

----------------------------
-- Registered Chat Commands
----------------------------

minetest.register_chatcommand( "scarlet", {
        description = "Formspec unit-conversion calculator",
        privs = { server = true },
        func = function( name, param )
		if param ~= "" then
			if is_match( param, "^([xy]) (.+)" ) then
				local axis = _[ 1 ]
				local expr = _[ 2 ]
				local res = UnitConversion( 72 ).evaluate( axis, expr )

				if not res then
					minetest.chat_send_player( name, "Parsing failure! Unrecognized token in expression." )
				else
					minetest.chat_send_player( name, string.format( "Result: %0.3fc", res ) )
				end
			else
				minetest.chat_send_player( name, "Invalid parameters supplied!" )
			end
		else
			local status = "Ready"
			local old_res = 0.0
			local old_expr = ""
			local expr = ""
			local axis = "x"
			local dpi = 72

			local function get_formspec( )
				local fs =
					"size[4s,8s;0.6c,0.4c]" ..
					"no_prepend[]" ..
					"bgcolor[#333333;false]" ..
					"field[0c,0c;4s;expr;" .. minetest.formspec_escape( expr ) .. "]" ..
					"box[0c,0.95c;2s,0.6c;" .. ( status == "Ready" and "#2222DD" or "#DD2222" ) .."]" ..
					"caption[0c,1.05c;2s,0.5c; " .. status .. "]" ..

					"margin[0c,1c]" ..
					"button[2c,0c;1i,0.5i;clear_entry;CE]" ..
					"button[3c,0c;1i,0.5i;clear;C]" ..
					"margin_end[]" ..

					"margin[0c,1.7c]" ..
					"button[0c,0c;1i,1i;num7;7]" ..
					"button[1c,0c;1i,1i;num8;8]" ..
					"button[2c,0c;1i,1i;num9;9]" ..
					"button[0c,1c;1i,1i;num4;4]" ..
					"button[1c,1c;1i,1i;num5;5]" ..
					"button[2c,1c;1i,1i;num6;6]" ..
					"button[0c,2c;1i,1i;num1;1]" ..
					"button[1c,2c;1i,1i;num2;2]" ..
					"button[2c,2c;1i,1i;num3;3]" ..
					"button[3c,0c;1i,1i;sub;-]" ..
					"button[3c,1c;1i,1i;add;+]" ..
					"button[3c,2c;1i,2s;eval;=]" ..
					"button[0c,3c;2s,1i;num0;0]" ..
					"button[2c,3c;1s,1i;dec;.]" ..
					"margin_end[]" ..

					"margin[0c,5.8c]" ..
					"button[0c,0c;1i,0.5i;unitC;c]" ..
					"button[1c,0c;1i,0.5i;unitI;i]" ..
					"button[2c,0c;1i,0.5i;unitP;p]" ..
					"button[3c,0c;1i,0.5i;unitD;d]" ..
					"button[0c,0.5c;1i,0.5i;varB;$B]" ..
					"button[1c,0.5c;1i,0.5i;varP;$P]" ..
					"button[2c,0.5c;1i,0.5i;varS;$S]" ..
					"button[3c,0.5c;1i,0.5i;varR;$R]" ..
					"margin_end[]" ..

					"margin[0c,7c]" ..
					"dropdown[0c,0c;1.9c;axis;X Axis,Y Axis;" .. ( axis == "x" and 1 or 2 ) .. "]" ..
					"dropdown[2c,0c;1.9c;dpi;72 dpi,96 dpi;" .. ( dpi == 72 and 1 or 2 ) .. "]" ..
					"margin_end[]"

				return scarlet.translate_72dpi( fs )
			end

	                local function on_close( meta, player, fields )
				axis = ( { ["X Axis"] = "x", ["Y Axis"] = "y" } )[ fields.axis ] or "x"
				dpi = ( { ["72 dpi"] = 72, ["96 dpi"] = 96 } )[ fields.dpi ] or 72

				if fields.clear then
					old_expr = expr
					expr = ""
					status = "Ready"
	                       	        minetest.update_form( name, get_formspec( ) )

				elseif fields.clear_entry then
					expr = old_expr
	                       	        minetest.update_form( name, get_formspec( ) )

				elseif fields.eval then
					local res = UnitConversion( dpi ).evaluate( axis, fields.expr, old_res )
					if res then
						old_res = res
						old_expr = expr
						expr = string.format( "%0.3fc", res )
						status = "Ready"
					else
						expr = fields.expr
						status = "Error"
					end
	                       	        minetest.update_form( name, get_formspec( ) )

				elseif fields.expr then
					old_expr = expr
					expr = fields.expr
					fields.expr = nil
					fields.axis = nil
					fields.dpi = nil

		                        local field_name = next( fields, nil )     -- use next since we only care about the name of the first button
        		                if field_name then
						local aliases = {
							sub = "-",
							add = "+",
							dec = ".",
							varB = "$B",
							varP = "$P",
							varS = "$S",
							varR = "$R",
							unitC = "c",
							unitI = "i",
							unitP = "p",
							unitD = "d",
						}

						if is_match( field_name, "^num([0-9])$" ) then
							expr = expr .. _[ 1 ]
						elseif aliases[ field_name ] then
							expr = expr .. aliases[ field_name ]
						end
		                       	        minetest.update_form( name, get_formspec( ) )
					end
				end
	                end

        	        minetest.create_form( nil, name, get_formspec( ), on_close )
		end
	end
} )
