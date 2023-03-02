/*
Explination:

	Many functions in unreal engine 4 are indireclty called via process event, instead of directly inside the code
	For example, in the projectile shoot function in ark survival evolved mobile - below
	there are a few key lines of code.
	


	this = (long *)(ulong)(byte)param_1;
	pcVar2 = *(code **)(*this + 0x230);
	uVar1 = UObject::FindFunctionChecked((UObject *)this,SUB81(DAT_07477e98,0));
  	(*pcVar2)(this,uVar1,&local_60);

  	"this" is the class pointer, so for this example it would be AShooterWeapon_Projectile

	"pcVar2" is the process event adress, which found in this line of code:
			 pcVar2 = *(code **)(*this + 0x230);

	"uVar1" is finds the adress of the function using FName saved in the games memory which is assigned to the function adress at launch


	the equivilent version of this written in real c++ code would be

	long AShooterWeapon_Projectile_MyWeapon = (pointer to the weapon you want to shoot);
	long ProcessEventAdressVTable = *AShooterWeapon_Projectile_MyWeapon;
	long ProcessEventFunctionAdress = *(long*)(ProcessEventAdressVTable + 0x230);
	long ServerFireProjectileFunction = UObject::FindFunctionChecked(AShooterWeapon_Projectile_MyWeapon , ServerFireProjectileFNamePointer);

	reinterpret_cast<void(__fastcall*)(long, long, long)>(ProcessEventFunctionAdress)(AShooterWeapon_Projectile_MyWeapon, FunctionAdress, (long)params);

	Hooking of these functions on iOS without jailbreak is normally impossible, and attempting to hook them on a jailed ipa would cause the app to crash
	However, since the ProcessEvent function is loaded from memory, and modifying the games memory is very easy even inside a jailed IPA, by 
	changing the ProcessEventFunctionAdress which is stored in the games memory we can redirect the call (*pcVar2)(this,uVar1,&local_60); to our own function,
	then we can modify paramaters or call other functions, and then either return without ever calling the origional function or return the origional function
	with modified paramters

	To modify the memory adress to our own function, we set the offset to (long)(FunctionName) which gets the memory adress of the function as a long


	Each Class has a seperate process event pointer - so if you want to hook a function from a specific class which gets called via process event 
	then you need to write a hook for that class too


	EXAMPLE:
	Jailed (non jailbroken) iOS
	*/
	static void (*origProcessEvent)(long UObject, long FunctionAdress, long Params) = (void(*)(long,long,long))getOffset(0x1234567);

	static void WeaponProcessEvent(long Object, long Function, void* params){
	    
	    NSString* FunctionName = GetObjectName(Function);

	    if([FunctionName isEqualToString:@"ServerFireProjectile"]){
			
			Vector ShootLocation = Read<Vector>(params + 0x0);
			Vector ShootRotation = Read<Vector>(params + 0xC);

			//Shoot the rocket 200 unreal units above where it is supposed to be shot from

			Vector NewShootLocation = {ShootLocation.X, ShootLocation.Y, ShootLocation.Z + 200};

			*(Vector*)(params + 0x0) = NewShootLocation;
			
			//Automatically Reload

			ProcessEvent(Object, L"ServerStartReload", 0);

	    }
	    //Calls back to the origional function

	    origProcessEvent(Object, Function, (long)params);
	}



	void ChangeProcessEventFunction(){
		long MyShooterWeapon = PointerChain -> AShooterWeapon_Projectile;
		*(long*)( *MyShooterWeapon + 0x230) = (long)WeaponProcessEvent;
	}






	/*

	An Equivilent example of this using MSHookFunction for jailbroken ios would be:
	EXAMPLE:
	Jailbroken iOS


	*/




void (*ProcessEventHOOK_orig)(void* Object, void* Function, void* Params);
void ProcessEventHOOK(void* Object, void* Function, void* Params) {

	NSString* FunctionName = GetObjectName((long)Function);

    if([FunctionName isEqualToString:@"ServerFireProjectile"]){
		
		Vector ShootLocation = Read<Vector>(params + 0x0);
		Vector ShootRotation = Read<Vector>(params + 0xC);

		//Shoot the rocket 200 unreal units above where it is supposed to be shot from

		Vector NewShootLocation = {ShootLocation.X, ShootLocation.Y, ShootLocation.Z + 200};
		
		//Automatically Reload

		ProcessEvent(Object, L"ServerStartReload", 0);

    }
    //Calls back to the origional function
    return ProcessEventHOOK_orig(Object,Function,Params);
}

#define HOOK(offset, ptr, orig) MSHookFunction((void *)getOffset(offset), (void *)ptr, (void **)&orig)

%ctor{
	HOOK(0x1234567, ProcessEventHOOK, ProcessEventHOOK_orig);
}
	/*

	
Function im using to demonstrate hooking:



	void AShooterWeapon_Projectile::ServerFireProjectile
               (FVector param_1,FVector_NetQuantizeNormal param_2)

{
  long *this;
  undefined8 uVar1;
  code *pcVar2;
  undefined4 in_s0;
  undefined4 in_s1;
  undefined4 in_s2;
  undefined4 in_s3;
  undefined4 in_s4;
  undefined4 in_s5;
  undefined4 local_60;
  undefined4 local_5c;
  undefined4 local_58;
  undefined4 local_54;
  undefined4 local_50;
  undefined4 local_4c;
  long *local_48;
  undefined4 local_40;
  undefined4 local_3c;
  undefined4 local_38;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  
  this = (long *)(ulong)(byte)param_1;
  local_48 = this;
  local_40 = in_s3;
  local_3c = in_s4;
  local_38 = in_s5;
  local_30 = in_s0;
  local_2c = in_s1;
  local_28 = in_s2;
  ShooterWeapon_Projectile_eventServerFireProjectile_Parms::
  ShooterWeapon_Projectile_eventServerFireProjectile_Parms
            ((ShooterWeapon_Projectile_eventServerFireProjectile_Parms *)&local_60);
  local_60 = local_30;
  local_5c = local_2c;
  local_58 = local_28;
  local_54 = local_40;
  local_50 = local_3c;
  local_4c = local_38;
  pcVar2 = *(code **)(*this + 0x230);
  uVar1 = UObject::FindFunctionChecked((UObject *)this,SUB81(DAT_07477e98,0));
  (*pcVar2)(this,uVar1,&local_60);
  return;
} */

