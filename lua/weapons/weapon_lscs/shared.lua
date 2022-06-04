
--SWEP.Base = "weapon_pvebase"
--DEFINE_BASECLASS( "weapon_pvebase" )
SWEP.Base = "weapon_base"

SWEP.Category			= "[LSCS]"

SWEP.PrintName		= "#lscsGlowstick"
SWEP.Author			= "Blu-x92 / Luna"

SWEP.ViewModel		= "models/weapons/c_arms.mdl"
SWEP.WorldModel		= "models/props_junk/PopCan01a.mdl"

SWEP.Spawnable		= false
SWEP.AdminOnly		= false

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo		= "none"

SWEP.RenderGroup = RENDERGROUP_BOTH 

SWEP.LSCS = true

SWEP._tblHilt = {}
SWEP._tblBlade = {}

SWEP.HAND_RIGHT = 1
SWEP.HAND_LEFT = 2
SWEP.HAND_STRING = {
	[SWEP.HAND_RIGHT] = "RH",
	[SWEP.HAND_LEFT] = "LH",
}

SWEP.AttackSound = "weapons/iceaxe/iceaxe_swing1.wav"
SWEP.ActivateSound = ""
SWEP.DisableSound = ""
SWEP.IdleSound = ""

function SWEP:SetupDataTables()
	self:NetworkVar( "Bool",0, "Active" )
	self:NetworkVar( "Bool",1, "NWDMGActive" )

	self:NetworkVar( "Float",0, "NWNextAttack" )
	self:NetworkVar( "Float",1, "NWGestureTime" )

	self:NetworkVar( "Float",2, "Length" )

	self:NetworkVar( "String",0, "HiltR")
	self:NetworkVar( "String",1, "HiltL")
	self:NetworkVar( "String",2, "BladeR")
	self:NetworkVar( "String",3, "BladeL")
end

function SWEP:GetHiltData( hand )
	local HiltR = self:GetHiltR()
	local HiltL = self:GetHiltL()

	if self._oldHiltR ~= HiltR then
		self._oldHiltR = HiltR

		local _HiltR = LSCS:GetHilt( HiltR )

		self._tblHilt[self.HAND_RIGHT] = _HiltR

		if CLIENT then
			self:UpdateWorldModel(self.HAND_RIGHT, _HiltR)
		end
	end

	if self._oldHiltL ~= HiltL then
		self._oldHiltL = HiltL

		local _HiltL = LSCS:GetHilt( HiltL )

		self._tblHilt[self.HAND_LEFT] = _HiltL

		if CLIENT then
			self:UpdateWorldModel(self.HAND_LEFT, _HiltL)
		end
	end

	if hand then
		return self._tblHilt[ hand ]
	else
		return self._tblHilt
	end
end

function SWEP:GetBladeData( hand )
	local BladeR = self:GetBladeR()
	local BladeL = self:GetBladeL()

	if self._oldBladeR ~= BladeR then
		self._oldBladeR = BladeR
		self._tblBlade[1] = LSCS:GetBlade( BladeR )
	end

	if self._oldBladeL ~= BladeL then
		self._oldBladeL = BladeL
		self._tblBlade[2] = LSCS:GetBlade( BladeL )
	end

	if hand then
		return self._tblBlade[ hand ]
	else
		return self._tblBlade
	end
end

function SWEP:BuildSounds()
	for _, data in pairs( self:GetBladeData() ) do
		local SND = data.sounds
		if SND then
			self.AttackSound = SND.Attack
			self.ActivateSound = SND.Activate
			self.DisableSound = SND.Disable
			self.IdleSound = SND.Idle
			break
		end
	end
end

function SWEP:SetDMGActive( active )
	self.b_dmgActive = active
	if SERVER then
		self:SetNWDMGActive( active )
	end
end

function SWEP:GetDMGActive()
	if CLIENT then
		if self:GetOwner() ~= LocalPlayer() then
			return self:GetNWDMGActive()
		else
			return self.b_dmgActive
		end
	else
		return self:GetNWDMGActive()
	end
end

function SWEP:SetNextPrimaryAttack( time )
	self:SetNWNextAttack( time )
	self.f_NextAttack = time
end

function SWEP:GetNextPrimaryAttack()
	return math.max( (self.f_NextAttack or 0), self:GetNWNextAttack())
end

function SWEP:CanPrimaryAttack()
	return self:GetNextPrimaryAttack() < CurTime()
end

function SWEP:Initialize()
	self:SetHoldType( "normal" )
	self:DrawShadow( false )
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end

function SWEP:DoAttackSound()
	if CLIENT then return end

	--ent:EmitSound internally calls SuppressHostEvents( )
	--which i need to break with this timer.Simple or it will 'sometimes' play two different sounds from the soundscript at the same time
	timer.Simple(0, function()
		if not IsValid( self ) then return end
		self:EmitSound( self.AttackSound )
	end)
end

function SWEP:Holster( wep )
	self:SetActive( false )

	self:FinishCombo()

	self:Think()

	return true
end

function SWEP:BeginAttack()
	self:SetDMGActive( true )
end

function SWEP:FinishAttack()
	self:SetDMGActive( false )

	local ply = self:GetOwner()
	if IsValid( ply ) then
		ply:lscsClearTimedMove()
	end
end

function SWEP:Deploy()
	return true
end

function SWEP:OwnerChanged()
end

function SWEP:Think()
	self:ComboThink()

	local Active = self:GetActive()

	local FT = FrameTime()
	local Length = self:GetLength()

	self:SetLength( Length + math.Clamp((Active and 1 or 0) - Length,-FT * 1.5,FT * 3) )

	if Active ~= self.OldActive then
		self.OldActive = Active

		if Active then
			self:BuildSounds()

			self:SetHoldType( self:GetCombo().HoldType )
			self:EmitSound( self.ActivateSound )
		else
			self:SetHoldType( "normal" )
			self:EmitSound( self.DisableSound )
		end
	end
end

