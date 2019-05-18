--------------------------------------------------------
-- Minetest :: Scarlet Mod (scarlet)
--
-- See README.txt for licensing and release notes.
-- Copyright (c) 2019, Leslie E. Krause
--------------------------------------------------------

ScarletDef = function ( screen_dpi, gui_scaling, has_padding )

        local image_size = 0.55 * ( screen_dpi or 72 ) * ( gui_scaling or 1 )

	-- calculate the dot pitch as images per pixel and cells per pixel
	-- using the "black magic" algorithm from guiFormSpecMenu.cpp
	local dot_pitch = {
		-- imgsize (images per pixel)
		ix = 1 / image_size,
		iy = 1 / image_size,
		-- spacing (cells per pixel)
                x = 1 / ( image_size * 5 / 4 ),
                y = 1 / ( image_size * 15 / 13 )
	}

	-- padding width and height in cell units
	-- original formula: image_size * 3.0 / 8
	local padding_width = has_padding and 0 or 3 / 10
	local padding_height = has_padding and 0 or 13 / 40

	-- nominal button height in cell units
	-- NB: this is 2x the value of m_button_height used internally!
	-- original formula: image_size * 15.0 / 13 * 0.35
	local button_height = 0.7

	-- cell margin width and height in cell units
	-- original formula: vx * spacing.x - ( spacing.x - imgsize.x )
	local cell_margin_width = 1 / 5
	local cell_margin_height = 2 / 15

	---------------------------
	-- unit conversion objects
	---------------------------

	local units = ( function ( )
		-- cell size measurements
        	local factors = {
                	i = { x = 4 / 5, y = 13 / 15 },			-- imgsize
	        	c = { x = 1, y = 1 },				-- spacing (unity)
        		b = { y = button_height },			-- 2 x m_button_height
	        }
        	local function get_x( v, u )
			return not factors[ u ] and math.floor( v ) * dot_pitch.x or v * factors[ u ].x
	        end
        	local function get_y( v, u )
			return not factors[ u ] and math.floor( v ) * dot_pitch.y or v * factors[ u ].y
	        end
		return { get_x = get_x, get_y = get_y }
	end )( )

	local iunits = ( function ( )
		-- image size measurements
		local factors = {
			i = { x = 1, y = 1 },				-- imgsize (unity)
			c = { x = 5 / 4, y = 15 / 13 },			-- spacing
			b = { y = button_height * 15 / 13 },		-- 2 x m_button_height
		}
        	local function get_x( v, u )
			return not factors[ u ] and math.floor( v ) * dot_pitch.ix or v * factors[ u ].x
	        end
        	local function get_y( v, u )
			return not factors[ u ] and math.floor( v ) * dot_pitch.iy or v * factors[ u ].y
	        end
		return { get_x = get_x, get_y = get_y }
	end )( )

	-----------------------
	-- translation helpers
	-----------------------

	local function element( name, params )
		return name .. "[" .. table.concat( params, ";" ) .. "]"
	end

	local function get_pos( params, pos_units, offsets )
		local replace = "%0.3f,%0.3f"
		local pos_x, u1, pos_y, u2 = string.match( params[ 1 ], "^(-?[0-9.]+)([icp]?),(-?[0-9.]+)([icpb]?)$" )

		if not pos_x then return end

		return string.format( replace,
			pos_units.get_x( pos_x, u1 ) + offsets[ 1 ],
			pos_units.get_y( pos_y, u2 ) + offsets[ 2 ]
		)
	end

	local function get_pos_and_dim_x( params, pos_units, dim_units, offsets )
		local replace = "%0.3f,%0.3f;%0.3f,0.000"
		local pos_x, u1, pos_y, u2 = string.match( params[ 1 ], "^(-?[0-9.]+)([icp]?),(-?[0-9.]+)([icpb]?)$" )
		local dim_x, u3 = string.match( params[ 2 ], "^([0-9.]+)([iscp]?)$" )

		if not pos_x or not dim_x then return end

		if u3 == "s" then
			u3 = "i"
			offsets[ 3 ] = offsets[ 3 ] + ( dim_x % 1 == 0 and dim_x - 1 or math.floor( dim_x ) ) * cell_margin_width
		end

		return string.format( replace,
			pos_units.get_x( pos_x, u1 ) + offsets[ 1 ],
			pos_units.get_y( pos_y, u2 ) + offsets[ 2 ],
			dim_units.get_x( dim_x, u3 ) + offsets[ 3 ]
		)
	end

	local function get_pos_and_dim( params, pos_units, dim_units, offsets )
		local replace = "%0.3f,%0.3f;%0.3f,%0.3f"
		local pos_x, u1, pos_y, u2 = string.match( params[ 1 ], "^(-?[0-9.]+)([icp]?),(-?[0-9.]+)([icpb]?)$" )
		local dim_x, u3, dim_y, u4 = string.match( params[ 2 ], "^([0-9.]+)([iscp]?),([0-9.]+)([iscpb]?)$" )

		if not pos_x or not dim_x then return end

		if u3 == "s" then
			u3 = "i"
			offsets[ 3 ] = offsets[ 3 ] + ( dim_x % 1 == 0 and dim_x - 1 or math.floor( dim_x ) ) * cell_margin_width
		end
		if u4 == "s" then
			u4 = "i"
			offsets[ 4 ] = offsets[ 4 ] + ( dim_y % 1 == 0 and dim_y - 1 or math.floor( dim_y ) ) * cell_margin_height
		end

		return string.format( replace,
			pos_units.get_x( pos_x, u1 ) + offsets[ 1 ],
			pos_units.get_y( pos_y, u2 ) + offsets[ 2 ],
			dim_units.get_x( dim_x, u3 ) + offsets[ 3 ],
			dim_units.get_y( dim_y, u4 ) + offsets[ 4 ]
		)
	end

	------------------------------
	-- generic element subclasses
	------------------------------

	local function ElemPos( pos_units, length )
		return function ( name, params )
			local pos = get_pos( params, pos_units, {
				-padding_width,
				-padding_height
			} )
			assert( pos and #params == length, "Cannot parse formspec element " .. name .. "[]" )
			return element( name, { pos, unpack( params, 2 ) } )
		end
	end

	local function ElemPosAndDim( pos_units, dim_units, length, is_unlimited )
		return function ( name, params )
			local pos_and_dim = get_pos_and_dim( params, pos_units, dim_units, {
				-padding_width,
				-padding_height,
				0,
				0
			} )
			assert( pos_and_dim and ( #params == length or is_unlimited and #params > length ), "Cannot parse formspec element " .. name .. "[]" )
			return element( name, { pos_and_dim, unpack( params, 3 ) } )
		end
	end

	local function ElemPosAndDimX( pos_units, dim_units, length, is_unlimited )
		return function ( name, params )
			local pos_and_dim_x = get_pos_and_dim_x( params, pos_units, dim_units, {
				-padding_width,
				-padding_height,
				0
			} )
			assert( pos_and_dim_x and ( #params == length or is_unlimited and #params > length ), "Cannot parse formspec element " .. name .. "[]" )
			return element( name, { pos_and_dim_x, unpack( params, 3 ) } )
		end
	end

	------------------------------
	-- special element subclasses 
	------------------------------

	local function SizeElement( )
		local pattern = "^(%d+)([iscp]?),(%d+)([iscpb]?)$"
		local replace = "%0.3f,%0.3f,true"

		return function ( name, params )
			local dim, count = string.gsub( params[ 1 ], pattern, function ( dim_x, u1, dim_y, u2 )
				return string.format( replace,
					units.get_x( dim_x, u1 ),
					units.get_y( dim_y, u2 )
				)
			end )
			assert( count == 1, "Cannot parse formspec element size[]" )
			return element( "size", { dim } )
		end
	end

	local function ListElement( )
		local pattern = "^(%d+)([icp]?),(%d+)([icpb]?)$"
		local replace = "%0.3f,%0.3f"

		return function ( name, params )
			local pos, count = string.gsub( params[ 3 ], pattern, function ( pos_x, u1, pos_y, u2 )
				return string.format( replace,
					units.get_x( pos_x, u1 ) - padding_width,
					units.get_y( pos_y, u2 ) - padding_height
				)
			end )
			assert( count == 1, "Cannot parse formspec element list[]" )
			return element( "list", { params[ 1 ], params[ 2 ], pos, unpack( params, 4 ) } )
		end
	end

	-- container[<x>,<y>]

	local function ContainerElement( )
		return function ( name, params )
			local pos = get_pos( params, units, { 0, 0 } )
			assert( pos and #params == 1, "Cannot parse formspec element container[]" )
			return element( "container", { pos } )
		end
	end

	-- background[<w>,<h>;<texture name>]

	local function BackgroundElement( )
		local pattern = "^(-?%d+),(-?%d+)$"
		local replace = "%d,%d;0,0"

		return function ( name, params )
			local dim, count = string.gsub( params[ 1 ], pattern, function ( pos_x, pos_y )
				return string.format( replace, -pos_x, -pos_y )
			end )
			assert( count == 1, "Cannot parse formspec element background[]" )
			return element( "background", { dim, params[ 2 ], "true" } )
		end
	end

	-- bgimage[<x>,<y>;<w>,<h>;<texture name>]

	local function BgImageElement( )
		-- original formula: vx * spacing.x - ( spacing.x - imgsize.x ) / 2
		local pos_offset_x = 0.5 * 1 / 5
		local pos_offset_y = 0.5 * 2 / 15

		return function ( name, params )
			local pos_and_dim = get_pos_and_dim( params, units, units, {
				-padding_width + pos_offset_x,
				-padding_height + pos_offset_y,
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
		-- original formula: ( vy + 7 / 30 ) * spacing.y - m_button_height
		local pos_offset_y = -7 / 30 + button_height / 2

		return function ( name, params )
			local pos = get_pos( params, units, {
				-padding_width,
				-padding_height + pos_offset_y,
			} )
			assert( pos and #params == 2, "Cannot parse formspec element " .. name .. "[]" )
			return element( is_vertical and "vertlabel" or "label", { pos, params[ 2 ] } )
		end
	end

	-- checkbox[<x>,<y>;<w>;<name>;<label>]

	local function CheckboxElement( )
		-- original formula: vy * spacing.y + ( imgsize.y / 2 ) - m_button_height
		local pos_offset_y = -13 / 30 + button_height / 2

		return function ( name, params )
			local pos = get_pos( params, units, {
				-padding_width,
				-padding_height + pos_offset_y,
			} )
			assert( pos and #params == 4, "Cannot parse formspec element checkbox[]" )
			return element( "checkbox", { pos, unpack( params, 3 ) } )
		end
	end

	-- button[<x>,<y>;<w>;<name>;<label>]

	local function ButtonElement( )
		return function ( name, params )
			local pos_and_dim = get_pos_and_dim( params, units, units, {
				-padding_width,
				-padding_height,
				cell_margin_width,
				cell_margin_height,
			} )
			assert( pos_and_dim and #params == 4, "Cannot parse formspec element " .. name .. "[]" )
			return element( "image_" .. name, { pos_and_dim, "", unpack( params, 3 ) } )
		end
	end

	-- image_button[<x>,<y>;<w>;<name>;<texture_name>;<label>]

	local function ImageButtonElement( )
		return function ( name, params )
			local pos_and_dim = get_pos_and_dim( params, units, units, {
				-padding_width,
				-padding_height,
				cell_margin_width,
				cell_margin_height,
			} )
			assert( pos_and_dim and ( #params == 5 or #params == 8 ), "Cannot parse formspec element " .. name .. "[]" )
			return element( name, { pos_and_dim, params[ 4 ], params[ 3 ], unpack( params, 5 ) } )
		end
	end

	-- item_image_button[<x>,<y>;<w>,<h>;<item name>;<name>;<label>]

	local function ItemImageButtonElement( )
		return function ( name, params )
			local pos_and_dim = get_pos_and_dim( params, units, units, {
				-padding_width,
				-padding_height,
				cell_margin_width,
				cell_margin_height,
			} )
			assert( pos_and_dim and #params == 5, "Cannot parse formspec element item_image_button[]" )
			return element( "item_image_button", { pos_and_dim, params[ 4 ], params[ 3 ], params[ 5 ] } )
		end
	end

	-- textlist[<x>,<y>;<w>,<h>;<name>;...]

	local function TextListElement( )
		return function ( name, params )
			local pos_and_dim = get_pos_and_dim( params, units, units, {
				-padding_width,
				-padding_height,
				0,
				0,
			} )
			assert( pos_and_dim and ( #params == 4 or #params == 5 ), "Cannot parse formspec element textlist[]" )
			return element( "textlist", { pos_and_dim, unpack( params, 3 ) } )
		end
	end

	-- dropdown[<x>,<y>;<w>,<h>;<name>;...]

	local function DropdownElement( )
		return function ( name, params )
			local pos_and_dim_x = get_pos_and_dim_x( params, units, units, {
				-padding_width,
				-padding_height,
				0,
				0,
			} )
			assert( pos_and_dim_x and #params == 5, "Cannot parse formspec element dropdown[]" )
			return element( "dropdown", { pos_and_dim_x, unpack( params, 3 ) } )
		end
	end

	-- pwdfield[<x>,<y>;<w>;<name>]

	local function PwdFieldElement( )
		return function ( name, params )
			local pos_and_dim_x = get_pos_and_dim_x( params, units, units, {
				0,
				button_height / 2,
				cell_margin_width,
			} )
			assert( pos_and_dim_x, #params == 3, "Cannot parse formspec element pwdfield[]" )
			return element( "pwdfield", { pos_and_dim_x, params[ 3 ], "" } )
		end
	end

	-- field[<x>,<y>;<w>;<name>;<default>]

	local function FieldElement( )
		return function ( name, params )
			local pos_and_dim_x = get_pos_and_dim_x( params, units, units, {
				0,
				button_height / 2,
				cell_margin_width,
			} )
			assert( pos_and_dim_x and #params == 4, "Cannot parse formspec element field[]" )
			return element( "field", { pos_and_dim_x, params[ 3 ], "", params[ 4 ] } )
		end
	end

	-- caption[<x>,<y>;<w>,<h>;<caption>]

	local function CaptionElement( )
		return function ( name, params )
			local pos_and_dim = get_pos_and_dim( params, units, units, {
				0,
				-button_height / 2,
				cell_margin_width,
				cell_margin_height + button_height / 2
			} )
			assert( pos_and_dim and #params == 3, "Cannot parse formspec element caption[]" )
			return element( "textarea", { pos_and_dim, "", params[ 3 ], "" } )
		end
	end

	-- textarea[<x>,<y>;<w>,<h>;<name>;<default>]

	local function TextAreaElement( )
		return function ( name, params )
			local pos_and_dim = get_pos_and_dim( params, units, units, {
				0,
				-button_height / 2,
				cell_margin_width,
				cell_margin_height + button_height / 2
			} )
			assert( pos_and_dim and #params == 4, "Cannot parse formspec element textarea[]" )
			return element( "textarea", { pos_and_dim, params[ 3 ], "", params[ 4 ] } )
		end
	end

	-- horz_scrollbar[<x>,<y>;<w>,<h>;<name>;<value>]
	-- vert_scrollbar[<x>,<y>;<w>,<h>;<name>;<value>]

	local function ScrollbarElement( orientation )
		return function ( name, params )
			local pos_and_dim = get_pos_and_dim( params, units, units, {
				-padding_width,
				-padding_height,
				0,
				0
			} )
			assert( pos_and_dim and #params == 4, "Cannot parse formspec element " .. name .. "[]" )
			return element( "scrollbar", { pos_and_dim, orientation, unpack( params, 3 ) } )
		end
	end

	-- area_tooltip[<x>,<y>;<w>,<h>;<name>;<tooltip_text>]

	local function AreaTooltipElement( )
		return function ( name, params )
			local pos_and_dim = get_pos_and_dim( params, units, units, {
				-padding_width,
				-padding_height,
				0,
				0
			} )
			assert( pos_and_dim and #params >= 3, "Cannot parse formspec element area_tooltip[]" )
			return element( "tooltip", { pos_and_dim, unpack( params, 3 ) } )
		end
	end

	-- tabheader[<x>,<y>;<w>,<h>;<name>;<tooltip_text>]

	local function TabHeaderElement( )
		return function ( name, params )
			local pos = get_pos( params, units, {
				0,
				0
			} )
			assert( pos and ( #params == 4 or #params == 6 ), "Cannot parse formspec element tabheader[]" )
			return element( "tabheader", { pos, unpack( params, 2 ) } )
		end
	end

	-------------------
	-- element parsers
	-------------------

	local element_parsers = {
		size			= SizeElement( ),
		list			= ListElement( ),
		background		= BackgroundElement( ),
		box			= ElemPosAndDim( units, units, 3, false ),
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
		image			= ElemPosAndDim( units, iunits, 3, false ),
		item_image		= ElemPosAndDim( units, iunits, 3, false ),
		field			= FieldElement( ),
		dropdown		= DropdownElement( ),
		textlist		= TextListElement( ),
		vert_scrollbar		= ScrollbarElement( "vertical" ),
		horz_scrollbar		= ScrollbarElement( "horizontal" ),
		table			= ElemPosAndDim( units, units, 5, false ),
		textarea		= TextAreaElement( ),
		caption			= CaptionElement( ),
		area_tooltip		= AreaTooltipElement( ),		-- added in 5.0 (https://github.com/minetest/minetest/pull/7469)
		container		= ContainerElement( ),			-- fixed in 5.0 (https://github.com/minetest/minetest/pull/7497)
		tabheader		= TabHeaderElement( ),
	}

	-------------------------
	-- translation interface
	-------------------------

	local function translate( fs )
		fs = string.gsub( fs, "([a-z_]+)%[(.-)%]", function( name, parts )
			local parser = element_parsers[ name ]
			if parser then
				local res = parser( name, string.split( parts, ";", true ) )
				return res
			end
		end )

		minetest.debug( "ACTION", "Result:" .. fs )
		return fs
	end

	return {
		-- public method
		translate = translate
	}
end

scarlet = {
	translate_96dpi = ScarletDef( 96, 1, false ).translate,
	translate_72dpi = ScarletDef( 72, 1, false ).translate
}
