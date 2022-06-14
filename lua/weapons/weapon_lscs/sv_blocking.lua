
function SWEP:SetNextDeflect( time )
	self._nextDeflect = time
end

function SWEP:CanDeflect()
	if not self:GetActive() or not self:GetCombo().DeflectBullets or self:IsBrokenSaber() then
		return false
	end

	return (self._nextDeflect or 0) < CurTime()
end

function SWEP:SetNextBlock( time )
	self._nextBlock = time
end

function SWEP:CanBlock()
	return (self._nextBlock or 0) < CurTime()
end

function SWEP:Block( dmginfo )
end

function SWEP:DeflectBullet( attacker, trace, dmginfo, bullet )
	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	if not self:CanDeflect() then ply:lscsSetShouldBleed( true ) return end

	local Forward = ply:EyeAngles():Forward()
	local BulletForward = bullet.Dir

	local AimDirToForwardDir = math.deg( math.acos( math.Clamp( Forward:Dot( bullet.Dir ) ,-1,1) ) )

	if AimDirToForwardDir < 60 then
		ply:lscsSetShouldBleed( true )

		return
	end
	if self:IsComboActive() then
		if LSCS.ComboInterupt[ self.LastAttack ] and not ply:lscsKeyDown( IN_ATTACK ) then
			self:CancelCombo( 0.1 )
			self:SetNextDeflect( CurTime() + 0.1 )

			ply:lscsPlayAnimation( LSCS.ComboInterupt[ self.LastAttack ] )

			self:PingPongBullet( ply, trace.HitPos - BulletForward  * 50, dmginfo, bullet )

			ply:EmitSound( "saber_pblock" )
		else
			ply:lscsSetShouldBleed( true )
		end

		return
	end

	ply:lscsPlayAnimation( "block"..math.random(1,3) )

	self:PingPongBullet( ply, trace.HitPos - BulletForward  * 50, dmginfo, bullet )

	return true
end

function SWEP:PingPongBullet( ply, pos, dmginfo, original_bullet )
	ply:lscsSetShouldBleed( false )

	ply:EmitSound( "saber_deflect_bullet" )

	local effectdata = EffectData()
		effectdata:SetOrigin( pos )
		effectdata:SetNormal( Vector(0,0,1) )
	util.Effect( "saber_block", effectdata, true, true )

	for _, Blockable in pairs( LSCS.BulletTracerDeflectable ) do
		if  string.match( original_bullet.TracerName, Blockable ) then
			local bullet = table.Copy( original_bullet )
			local aimpos = ply:GetEyeTrace().HitPos

			local effectdata = EffectData()
				effectdata:SetStart( pos )
				effectdata:SetOrigin( aimpos )
				effectdata:SetEntity( self )
			util.Effect( bullet.TracerName, effectdata )

			timer.Simple(0.05, function() -- dont deflect at the same frame. Prevent infinite loop when saber v saber bullet deflecting
				if not IsValid( ply ) or not IsValid( self ) then return end

				bullet.Num	= 1
				bullet.Attacker = ply
				bullet.TracerName = ""
				bullet.Tracer = 0
				bullet.Src		= pos
				bullet.Dir		= (aimpos - pos):GetNormalized()
				bullet.IgnoreEntity = ply

				ply:FireBullets( bullet )
			end)
		end
	end

	dmginfo:SetDamage( 0 )
end