//to do: add action: "copy" files with timedate stamp or overwrite. Create native bool for checking a file with X days at X path. accept multiple extensions, separated by semicolon. "Rename" action.
#pragma semicolon 1
#pragma dynamic 131072 //increase stack space to from 4 kB to 131072 cells (or 512KB, a cell is 4 bytes).*/

#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig or https://forums.alliedmods.net/showthread.php?p=1862459

#define PLUGIN_VERSION "4.2"
//#define DEGUGMODE ""	//uncomment this define to compile with debugging. Be sure to switch back to a compilation without debugging after you have finished your debug.

new Handle:g_hLog = INVALID_HANDLE;
new bool:g_bLog;					//Enable logs

new Handle:hKeyValues = INVALID_HANDLE;

new String:g_sCleanPath[PLATFORM_MAX_PATH];		//deleted files log file path
new String:g_sDebugPath[PLATFORM_MAX_PATH];		//debug file path

public Plugin:myinfo =
{
	name = "TOGs File Cleaner",
	author = "That One Guy",
	description = "Performs file actions for logs of a desired extension, filenames, and age at specified paths",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=188078"
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("togfilecleaner");
	AutoExecConfig_CreateConVar("tfc_version", PLUGIN_VERSION, "TOGs File Cleaner: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hLog = AutoExecConfig_CreateConVar("tfc_log", "0", "Enables logging of files that actions are taken on.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hLog, OnCVarChange);
	g_bLog = GetConVarBool(g_hLog);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	//path builds
	BuildPath(Path_SM, g_sDebugPath, sizeof(g_sDebugPath), "logs/togsfilecleanerdebug.log");
	BuildPath(Path_SM, g_sCleanPath, sizeof(g_sCleanPath), "logs/togsfilecleaner.log");
}

public OnCVarChange(Handle:hCVar, const String:sOldValue[], const String:sNewValue[])
{
	if(hCVar == g_hLog)
	{
		g_bLog = GetConVarBool(g_hLog);
	}
}

public OnMapStart()
{
	RunSetups();
}

RunSetups()
{
	decl String:sCfgPath[256];
	BuildPath(Path_SM, sCfgPath, sizeof(sCfgPath), "configs/togfilecleaner.txt");
	
	if(!FileExists(sCfgPath))
	{
#if defined DEGUGMODE
		LogToFileEx(g_sDebugPath, "===================================================================================================================");
		LogToFileEx(g_sDebugPath, "==================================== File Not Found: %s ====================================", sCfgPath);
		LogToFileEx(g_sDebugPath, "===================================================================================================================");
#endif
		SetFailState("File Not Found: %s", sCfgPath);
		return;
	}
	
	hKeyValues = CreateKeyValues("Setups");
	
	if(!FileToKeyValues(hKeyValues, sCfgPath))
	{
		SetFailState("Improper structure for configuration file: %s", sCfgPath);
		CloseHandle(hKeyValues);
		return;
	}

#if defined DEGUGMODE
	LogToFileEx(g_sDebugPath, "File path for setups: %s", sCfgPath);
	LogToFileEx(g_sDebugPath, "------------------------------------------------------------------------------------------------------");
	LogToFileEx(g_sDebugPath, "Running setups.");
	LogToFileEx(g_sDebugPath, "");
#endif
	
	if(KvJumpToKey(hKeyValues, "SM Directory Setups"))
	{
		if(KvGotoFirstSubKey(hKeyValues))
		{
#if defined DEGUGMODE
			LogToFileEx(g_sDebugPath, "==============================================================================================================================");
			LogToFileEx(g_sDebugPath, "------------------------------------------------------------------------------------------------------------------------------");
			LogToFileEx(g_sDebugPath, "SM Setups config entered");
			LogToFileEx(g_sDebugPath, "------------------------------------------------------------------------------------------------------------------------------");
			LogToFileEx(g_sDebugPath, "==============================================================================================================================");
#endif
			
			do
			{
				decl String:sBuffer[PLATFORM_MAX_PATH];
				new Handle:hDirectory = INVALID_HANDLE;
				new FileType:type = FileType_Unknown;
				new Float:fDaysOld;
				
				decl String:sDirectory[PLATFORM_MAX_PATH], String:sString[30], String:sExt[30], String:sExclude[30], String:sSectionName[30], String:sAction[30], String:sNewFilePath[PLATFORM_MAX_PATH];
				new iEnabled, Float:fDays, iCase;
				iEnabled = KvGetNum(hKeyValues, "enabled", 0);
				KvGetString(hKeyValues, "filepath", sDirectory, sizeof(sDirectory), "logs");
				fDays = KvGetFloat(hKeyValues, "days", 3.0);
				KvGetString(hKeyValues, "string", sString, sizeof(sString), "none");
				iCase = KvGetNum(hKeyValues, "case", 1);
				KvGetString(hKeyValues, "extension", sExt, sizeof(sExt), "any");
				KvGetString(hKeyValues, "exclude", sExclude, sizeof(sExclude), "");
				KvGetString(hKeyValues, "action", sAction, sizeof(sAction), "delete");
				KvGetString(hKeyValues, "newpath", sNewFilePath, sizeof(sNewFilePath), "none");
				
				KvGetSectionName(hKeyValues, sSectionName, sizeof(sSectionName));
				
#if defined DEGUGMODE
				LogToFileEx(g_sDebugPath, "==============================================================================================================================");
				LogToFileEx(g_sDebugPath, "Setup: %s", sSectionName);
				LogToFileEx(g_sDebugPath, "==============================================================================================================================");
				LogToFileEx(g_sDebugPath, "Settings set as - enabled: %i, filepath: %s, days: %f, string: %s, case: %i, extension: %s, exlude: %s", iEnabled, sDirectory, fDays, sString, iCase, sExt, sExclude);
#endif
				
				BuildPath(Path_SM, sDirectory, sizeof(sDirectory), "%s", sDirectory);

				if(DirExists(sDirectory))
				{
#if defined DEGUGMODE
					LogToFileEx(g_sDebugPath, "Directory found for RunSetups(): %s", sDirectory);
					LogToFileEx(g_sDebugPath, "");
					
					if(iCase)
					{
						LogToFileEx(g_sDebugPath, "Looking for files with string (case sensitive) and extensions, excluding files with string: '%s' and '%s', '%s'", sString, sExt, sExclude);
						LogToFileEx(g_sDebugPath, "");
					}
					else
					{
						LogToFileEx(g_sDebugPath, "Looking for files with string (case insensitive) and extensions, excluding files with string: '%s' and '%s', '%s'", sString, sExt, sExclude);
						LogToFileEx(g_sDebugPath, "");
					}
#endif
					
					if(iEnabled)
					{
#if defined DEGUGMODE
						LogToFileEx(g_sDebugPath, ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> File Search Beginning <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
#endif
						
						hDirectory = OpenDirectory(sDirectory);
						if(hDirectory != INVALID_HANDLE)
						{
							while( ReadDirEntry(hDirectory, sBuffer, sizeof(sBuffer), type))
							{
								if(type == FileType_File)
								{
									//if case sensitive
									if(iCase)
									{						
										if(StrContains(sBuffer, sString, true) != -1)
										{
#if defined DEGUGMODE
											LogToFileEx(g_sDebugPath, "File %s contains string %s (case sensitive)", sBuffer, sString);
											LogToFileEx(g_sDebugPath, "");
#endif
											
											if((StrContains(sBuffer, sExt, false) != -1) || StrEqual(sExt, "any", false))
											{
#if defined DEGUGMODE
												LogToFileEx(g_sDebugPath, "File %s contains required extension: %s", sBuffer, sExt);
												LogToFileEx(g_sDebugPath, "");
#endif
												
												if((StrContains(sBuffer, sExclude, false) == -1) && !StrEqual(sExclude, "", false))
												{
#if defined DEGUGMODE
													LogToFileEx(g_sDebugPath, "File %s excludes the string %s", sBuffer, sExclude);
													LogToFileEx(g_sDebugPath, "");
#endif
													
													decl String:sDelFile[PLATFORM_MAX_PATH];
													Format(sDelFile, sizeof(sDelFile), "%s/%s", sDirectory, sBuffer);
													fDaysOld = ((float(GetTime() - GetFileTime(sDelFile, FileTime_LastChange))/86400));
													
													if(GetFileTime(sDelFile, FileTime_LastChange) < (GetTime() - (86400 * RoundFloat(fDays)) + 30))
													{
														if(StrEqual(sAction, "delete", false))
														{
															DeleteFile(sDelFile);
															
#if defined DEGUGMODE
															LogToFileEx(g_sDebugPath, "File deleted: %s (%f days old)", sDelFile, fDaysOld);
															LogToFileEx(g_sDebugPath, "");
#endif
															
															if(g_bLog)
															{
																LogToFileEx(g_sCleanPath, "Cleared old file: %s (%f days old)", sDelFile, fDaysOld);
															}
														}
														else if(StrEqual(sAction, "move", false) && !StrEqual(sNewFilePath, "none", false))
														{
															decl String:sMoveBuild[PLATFORM_MAX_PATH];
															BuildPath(Path_SM, sMoveBuild, sizeof(sMoveBuild), "%s",sNewFilePath);
															MoveFile(sDirectory, sMoveBuild, sBuffer);
															
#if defined DEGUGMODE
															LogToFileEx(g_sDebugPath, "File moved: %s (%f days old) to %s", sDelFile, fDaysOld, sNewFilePath);
															LogToFileEx(g_sDebugPath, "");
#endif
															
															if(g_bLog)
															{
																LogToFileEx(g_sCleanPath, "Moved old file: %s (%f days old) to %s", sDelFile, fDaysOld, sNewFilePath);
															}
														}
														else if(StrEqual(sAction, "copy", false) && !StrEqual(sNewFilePath, "none", false))
														{
															decl String:sMoveBuild[PLATFORM_MAX_PATH];
															BuildPath(Path_SM, sMoveBuild, sizeof(sMoveBuild), "%s",sNewFilePath);
															CopyFile_NotTxt_OverWriteExisting(sDirectory, sMoveBuild, sBuffer);
															
#if defined DEGUGMODE
															LogToFileEx(g_sDebugPath, "File copied: %s (%f days old) to %s", sDelFile, fDaysOld, sNewFilePath);
															LogToFileEx(g_sDebugPath, "");
#endif
															
															if(g_bLog)
															{
																LogToFileEx(g_sCleanPath, "Copied old file: %s (%f days old) to %s", sDelFile, fDaysOld, sNewFilePath);
															}
														}
													}
													else
													{
#if defined DEGUGMODE
														LogToFileEx(g_sDebugPath, "File %s ignored - Not old enough: %f days old", sDelFile, fDaysOld);
														LogToFileEx(g_sDebugPath, "");
#endif
													}
												}
												else
												{
#if defined DEGUGMODE
													LogToFileEx(g_sDebugPath, "File %s ignored for containing string %s", sBuffer, sExclude);
													LogToFileEx(g_sDebugPath, "");
#endif
												}
											}
											else
											{
#if defined DEGUGMODE
												LogToFileEx(g_sDebugPath, "File %s ignored for not having required extension: %s", sBuffer, sExt);
												LogToFileEx(g_sDebugPath, "");
#endif
											}
										}
										else
										{
#if defined DEGUGMODE
											LogToFileEx(g_sDebugPath, "File %s ignored for not containing string %s (case sensitive)", sBuffer, sString);
											LogToFileEx(g_sDebugPath, "");
#endif
										}
									}
									else	//case insensitive
									{
										if(StrContains(sBuffer, sString, false) != -1)
										{
#if defined DEGUGMODE
											LogToFileEx(g_sDebugPath, "File %s contains string %s (case insensitive)", sBuffer, sString);
											LogToFileEx(g_sDebugPath, "");
#endif

											if((StrContains(sBuffer, sExt, false) != -1) || StrEqual(sExt, "any", false))
											{
#if defined DEGUGMODE
												LogToFileEx(g_sDebugPath, "File %s contains required extension: %s", sBuffer, sExt);
												LogToFileEx(g_sDebugPath, "");
#endif
												
												if((StrContains(sBuffer, sExclude, false) == -1) && !StrEqual(sExclude, "", false))
												{
#if defined DEGUGMODE
													LogToFileEx(g_sDebugPath, "File %s does not contain string %s", sBuffer, sExclude);
													LogToFileEx(g_sDebugPath, "");
#endif
													
													decl String:sDelFile[PLATFORM_MAX_PATH];
													Format(sDelFile, sizeof(sDelFile), "%s/%s", sDirectory, sBuffer);
													fDaysOld = ((float(GetTime() - GetFileTime(sDelFile, FileTime_LastChange)))/86400);
													
													if(GetFileTime(sDelFile, FileTime_LastChange) < (GetTime() - (86400 * RoundFloat(fDays)) + 30))
													{
														if(StrEqual(sAction, "delete", false))
														{
															DeleteFile(sDelFile);
															
#if defined DEGUGMODE
															LogToFileEx(g_sDebugPath, "File deleted: %s (%f days old)", sDelFile, fDaysOld);
															LogToFileEx(g_sDebugPath, "");
#endif
															
															if(g_bLog)
															{
																LogToFileEx(g_sCleanPath, "Cleared old file: %s (%f days old)", sDelFile, fDaysOld);
															}
														}
														else if(StrEqual(sAction, "move", false) && !StrEqual(sNewFilePath, "none", false))
														{
															decl String:sMoveBuild[PLATFORM_MAX_PATH];
															BuildPath(Path_SM, sMoveBuild, sizeof(sMoveBuild), "%s",sNewFilePath);
															MoveFile(sDirectory, sMoveBuild, sBuffer);
															
#if defined DEGUGMODE
															LogToFileEx(g_sDebugPath, "File moved: %s (%f days old) to %s", sDelFile, fDaysOld, sNewFilePath);
															LogToFileEx(g_sDebugPath, "");
#endif
															
															if(g_bLog)
															{
																LogToFileEx(g_sCleanPath, "Moved old file: %s (%f days old) to %s", sDelFile, fDaysOld, sNewFilePath);
															}
														}
														else if(StrEqual(sAction, "copy", false) && !StrEqual(sNewFilePath, "none", false))
														{
															decl String:sMoveBuild[PLATFORM_MAX_PATH];
															BuildPath(Path_SM, sMoveBuild, sizeof(sMoveBuild), "%s",sNewFilePath);
															CopyFile_NotTxt_OverWriteExisting(sDirectory, sMoveBuild, sBuffer);
															
#if defined DEGUGMODE
															LogToFileEx(g_sDebugPath, "File copied: %s (%f days old) to %s", sDelFile, fDaysOld, sNewFilePath);
															LogToFileEx(g_sDebugPath, "");
#endif
															
															if(g_bLog)
															{
																LogToFileEx(g_sCleanPath, "Copied old file: %s (%f days old) to %s", sDelFile, fDaysOld, sNewFilePath);
															}
														}
													}
													else
													{
#if defined DEGUGMODE
														LogToFileEx(g_sDebugPath, "File %s ignored - Not old enough: %f days old", sDelFile, fDaysOld);
														LogToFileEx(g_sDebugPath, "");
#endif
													}
												}
												else
												{
#if defined DEGUGMODE
													LogToFileEx(g_sDebugPath, "File %s ignored for containing string %s", sBuffer, sExclude);
													LogToFileEx(g_sDebugPath, "");
#endif
												}
											}
											else
											{
#if defined DEGUGMODE
												LogToFileEx(g_sDebugPath, "File %s ignored for not having required extension %s", sBuffer, sExt);
												LogToFileEx(g_sDebugPath, "");
#endif
											}
										}
										else
										{
#if defined DEGUGMODE
											LogToFileEx(g_sDebugPath, "File %s ignored for not containing string %s (case insensitive)", sBuffer, sString);
											LogToFileEx(g_sDebugPath, "");
#endif
										}
									}
#if defined DEGUGMODE
									LogToFileEx(g_sDebugPath, "------------------------------------------------------ Next File -------------------------------------------------------------");
#endif
								}
							}
						}
						
#if defined DEGUGMODE
						LogToFileEx(g_sDebugPath, "---------------------------------------------------- File Search Complete ----------------------------------------------------");
#endif
					}
					else
					{
#if defined DEGUGMODE
						LogToFileEx(g_sDebugPath, "================================ Setup Ignored - enabled not set to 1: %s ================================", sSectionName);
						LogToFileEx(g_sDebugPath, "");
#endif
					}
				}
				
				if(hDirectory != INVALID_HANDLE)
				{
					CloseHandle(hDirectory);
					hDirectory = INVALID_HANDLE;
				}
			} while(KvGotoNextKey(hKeyValues, false));
			KvGoBack(hKeyValues);
		}
	}
	
	KvGoBack(hKeyValues);
	if(KvJumpToKey(hKeyValues, "Root Directory Setups"))
	{
		if(KvGotoFirstSubKey(hKeyValues))
		{
#if defined DEGUGMODE
			LogToFileEx(g_sDebugPath, "==============================================================================================================================");
			LogToFileEx(g_sDebugPath, "------------------------------------------------------------------------------------------------------------------------------");
			LogToFileEx(g_sDebugPath, "Root Setups config entered");
			LogToFileEx(g_sDebugPath, "------------------------------------------------------------------------------------------------------------------------------");
			LogToFileEx(g_sDebugPath, "==============================================================================================================================");
#endif
			
			do
			{
				new String:sBuffer[256];
				new Handle:hDirectory = INVALID_HANDLE;
				new FileType:type = FileType_Unknown;
				new Float:fDaysOld;
				
				decl String:sRootFilePath[256], String:sString[30], String:sExt[30], String:sExclude[30], String:sSectionName[30], String:sRootAction[30], String:sNewRootFilePath[256];
				new iRootEnabled, Float:fRootDays, iRootCase;
				iRootEnabled = KvGetNum(hKeyValues, "enabled", 0);
				KvGetString(hKeyValues, "filepath", sRootFilePath, sizeof(sRootFilePath), "");
				fRootDays = KvGetFloat(hKeyValues, "days", 3.0);
				KvGetString(hKeyValues, "string", sString, sizeof(sString), "none");
				iRootCase = KvGetNum(hKeyValues, "case", 1);
				KvGetString(hKeyValues, "extension", sExt, sizeof(sExt), "any");
				KvGetString(hKeyValues, "exclude", sExclude, sizeof(sExclude), "");
				KvGetString(hKeyValues, "action", sRootAction, sizeof(sRootAction), "delete");
				KvGetString(hKeyValues, "newpath", sNewRootFilePath, sizeof(sNewRootFilePath), "none");
				
				KvGetSectionName(hKeyValues, sSectionName, sizeof(sSectionName));
				
#if defined DEGUGMODE
				LogToFileEx(g_sDebugPath, "==============================================================================================================================");
				LogToFileEx(g_sDebugPath, "Setup: %s", sSectionName);
				LogToFileEx(g_sDebugPath, "==============================================================================================================================");
				LogToFileEx(g_sDebugPath, "Settings set as - enabled: %i, filepath: %s, days: %f, string: %s, case: %i, extension: %s, exlude: %s", iRootEnabled, sRootFilePath, fRootDays, sString, iRootCase, sExt, sExclude);
#endif

				if(DirExists(sRootFilePath) || StrEqual(sRootFilePath, "", false))
				{
#if defined DEGUGMODE
					LogToFileEx(g_sDebugPath, "Directory found for RunSetups(): %s", sRootFilePath);
					LogToFileEx(g_sDebugPath, "");
					
					if(iRootCase)
					{
						LogToFileEx(g_sDebugPath, "Looking for files with string (case sensitive) and extensions, excluding files with string: '%s' and '%s', '%s'", sString, sExt, sExclude);
						LogToFileEx(g_sDebugPath, "");
					}
					else
					{
						LogToFileEx(g_sDebugPath, "Looking for files with string (case insensitive) and extensions, excluding files with string: '%s' and '%s', '%s'", sString, sExt, sExclude);
						LogToFileEx(g_sDebugPath, "");
					}
#endif
					
					if(iRootEnabled)
					{
#if defined DEGUGMODE
						LogToFileEx(g_sDebugPath, ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> File Search Beginning <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
#endif
						
						hDirectory = OpenDirectory(sRootFilePath);
						if(hDirectory != INVALID_HANDLE)
						{
							while(ReadDirEntry(hDirectory, sBuffer, sizeof(sBuffer), type))
							{
								if(type == FileType_File)
								{
									//if case sensitive
									if(iRootCase)
									{						
										if(StrContains(sBuffer, sString, true) != -1)
										{
#if defined DEGUGMODE
											LogToFileEx(g_sDebugPath, "File %s contains string %s (case sensitive)", sBuffer, sString);
											LogToFileEx(g_sDebugPath, "");
#endif

											if((StrContains(sBuffer, sExt, false) != -1) || StrEqual(sExt, "any", false))
											{
#if defined DEGUGMODE
												LogToFileEx(g_sDebugPath, "File %s contains required extension: %s", sBuffer, sExt);
												LogToFileEx(g_sDebugPath, "");
#endif
												
												if((StrContains(sBuffer, sExclude, false) == -1) && !StrEqual(sExclude, "", false))
												{
#if defined DEGUGMODE
													LogToFileEx(g_sDebugPath, "File %s excludes the string %s", sBuffer, sExclude);
													LogToFileEx(g_sDebugPath, "");
#endif
													
													decl String:sDelFile[PLATFORM_MAX_PATH];
													Format(sDelFile, sizeof(sDelFile), "%s/%s", sRootFilePath, sBuffer);
													fDaysOld = ((float(GetTime() - GetFileTime(sDelFile, FileTime_LastChange)))/86400);
													if(GetFileTime(sDelFile, FileTime_LastChange) < (GetTime() - (86400 * RoundFloat(fRootDays)) + 30))
													{
														if(StrEqual(sRootAction, "delete", false))
														{
															DeleteFile(sDelFile);
															
#if defined DEGUGMODE
															LogToFileEx(g_sDebugPath, "File deleted: %s (%f days old)", sDelFile, fDaysOld);
															LogToFileEx(g_sDebugPath, "");
#endif
															
															if(g_bLog)
															{
																LogToFileEx(g_sCleanPath, "Cleared old file: %s (%f days old)", sDelFile, fDaysOld);
															}
														}
														else if(StrEqual(sRootAction, "move", false) && !StrEqual(sNewRootFilePath, "none", false))
														{
															MoveFile(sRootFilePath, sNewRootFilePath, sBuffer);

#if defined DEGUGMODE
															LogToFileEx(g_sDebugPath, "File moved: %s (%f days old) to %s", sDelFile, fDaysOld, sNewRootFilePath);
															LogToFileEx(g_sDebugPath, "");
#endif
															
															if(g_bLog)
															{
																LogToFileEx(g_sCleanPath, "Moved old file: %s (%f days old) to %s", sDelFile, fDaysOld, sNewRootFilePath);
															}
														}
														else if(StrEqual(sRootAction, "copy", false) && !StrEqual(sNewRootFilePath, "none", false))
														{
															CopyFile_NotTxt_OverWriteExisting(sRootFilePath, sNewRootFilePath, sBuffer);

#if defined DEGUGMODE
															LogToFileEx(g_sDebugPath, "File copied: %s (%f days old) to %s", sDelFile, fDaysOld, sNewRootFilePath);
															LogToFileEx(g_sDebugPath, "");
#endif
															
															if(g_bLog)
															{
																LogToFileEx(g_sCleanPath, "Copied old file: %s (%f days old) to %s", sDelFile, fDaysOld, sNewRootFilePath);
															}
														}
													}
													else
													{
#if defined DEGUGMODE
														LogToFileEx(g_sDebugPath, "File %s ignored - Not old enough: %f days old", sDelFile, fDaysOld);
														LogToFileEx(g_sDebugPath, "");
#endif
													}
												}
												else
												{
#if defined DEGUGMODE
													LogToFileEx(g_sDebugPath, "File %s ignored for containing string %s", sBuffer, sExclude);
													LogToFileEx(g_sDebugPath, "");
#endif
												}
											}
											else
											{
#if defined DEGUGMODE
												LogToFileEx(g_sDebugPath, "File %s ignored for not having required extension: %s", sBuffer, sExt);
												LogToFileEx(g_sDebugPath, "");
#endif
											}
										}
										else
										{
#if defined DEGUGMODE
											LogToFileEx(g_sDebugPath, "File %s ignored for not containing string %s (case sensitive)", sBuffer, sString);
											LogToFileEx(g_sDebugPath, "");
#endif
										}
									}
									else	//case insensitive
									{
										if(StrContains(sBuffer, sString, false) != -1)
										{
#if defined DEGUGMODE
											LogToFileEx(g_sDebugPath, "File %s contains string %s (case insensitive)", sBuffer, sString);
											LogToFileEx(g_sDebugPath, "");
#endif

											if((StrContains(sBuffer, sExt, false) != -1) || StrEqual(sExt, "any", false))
											{
#if defined DEGUGMODE
												LogToFileEx(g_sDebugPath, "File %s contains required extension: %s", sBuffer, sExt);
												LogToFileEx(g_sDebugPath, "");
#endif
												
												if((StrContains(sBuffer, sExclude, false) == -1) && !StrEqual(sExclude, "", false))
												{
#if defined DEGUGMODE
													LogToFileEx(g_sDebugPath, "File %s does not contain string %s", sBuffer, sExclude);
													LogToFileEx(g_sDebugPath, "");
#endif
													
													decl String:sDelFile[PLATFORM_MAX_PATH];
													Format(sDelFile, sizeof(sDelFile), "%s/%s", sRootFilePath, sBuffer);
													fDaysOld = ((float(GetTime() - GetFileTime(sDelFile, FileTime_LastChange)))/86400);
													
													if(GetFileTime(sDelFile, FileTime_LastChange) < (GetTime() - (86400 * RoundFloat(fRootDays)) + 30))
													{
														if(StrEqual(sRootAction, "delete", false))
														{
															DeleteFile(sDelFile);
															
#if defined DEGUGMODE
															LogToFileEx(g_sDebugPath, "File deleted: %s (%f days old)", sDelFile, fDaysOld);
															LogToFileEx(g_sDebugPath, "");
#endif
															
															if(g_bLog)
															{
																LogToFileEx(g_sCleanPath, "Cleared old file: %s (%f days old)", sDelFile, fDaysOld);
															}
														}
														else if(StrEqual(sRootAction, "move", false) && !StrEqual(sNewRootFilePath, "none", false))
														{
															MoveFile(sRootFilePath, sNewRootFilePath, sBuffer);
															
#if defined DEGUGMODE
															LogToFileEx(g_sDebugPath, "File moved: %s (%f days old) to %s", sDelFile, fDaysOld, sNewRootFilePath);
															LogToFileEx(g_sDebugPath, "");
#endif
															
															if(g_bLog)
															{
																LogToFileEx(g_sCleanPath, "Moved old file: %s (%f days old) to %s", sDelFile, fDaysOld, sNewRootFilePath);
															}
														}
														else if(StrEqual(sRootAction, "copy", false) && !StrEqual(sNewRootFilePath, "none", false))
														{
															CopyFile_NotTxt_OverWriteExisting(sRootFilePath, sNewRootFilePath, sBuffer);
#if defined DEGUGMODE
															LogToFileEx(g_sDebugPath, "File copied: %s (%f days old) to %s", sDelFile, fDaysOld, sNewRootFilePath);
															LogToFileEx(g_sDebugPath, "");
#endif
															
															if(g_bLog)
															{
																LogToFileEx(g_sCleanPath, "Copied old file: %s (%f days old) to %s", sDelFile, fDaysOld, sNewRootFilePath);
															}
														}
													}
													else
													{
#if defined DEGUGMODE
														LogToFileEx(g_sDebugPath, "File %s ignored - Not old enough: %f days old", sDelFile, fDaysOld);
														LogToFileEx(g_sDebugPath, "");
#endif
													}
												}
												else
												{
#if defined DEGUGMODE
													LogToFileEx(g_sDebugPath, "File %s ignored for containing string %s", sBuffer, sExclude);
													LogToFileEx(g_sDebugPath, "");
#endif
												}
											}
											else
											{
#if defined DEGUGMODE
												LogToFileEx(g_sDebugPath, "File %s ignored for not having required extension: %s", sBuffer, sExt);
												LogToFileEx(g_sDebugPath, "");
#endif
											}
										}
										else
										{
#if defined DEGUGMODE
											LogToFileEx(g_sDebugPath, "File %s ignored for not containing string %s (case insensitive)", sBuffer, sString);
											LogToFileEx(g_sDebugPath, "");
#endif
										}
									}
									
#if defined DEGUGMODE
									LogToFileEx(g_sDebugPath, "------------------------------------------------------ Next File -------------------------------------------------------------");
#endif
								}
							}
						}
						else
						{
#if defined DEGUGMODE
							LogToFileEx(g_sDebugPath, "Unable to open directory - bad handle for file path: %s", sRootFilePath);
							LogToFileEx(g_sDebugPath, "");
#endif
						}
						
#if defined DEGUGMODE
						LogToFileEx(g_sDebugPath, "---------------------------------------------------- File Search Complete ----------------------------------------------------");
#endif
					}
					else
					{
#if defined DEGUGMODE
						LogToFileEx(g_sDebugPath, "================================ Setup Ignored - enabled not set to 1: %s ================================", sSectionName);
						LogToFileEx(g_sDebugPath, "");
#endif
					}
				}
				else
				{
#if defined DEGUGMODE
					LogToFileEx(g_sDebugPath, "Directory does not exist: %s", sRootFilePath);
					LogToFileEx(g_sDebugPath, "");
#endif
				}
				
				if(hDirectory != INVALID_HANDLE)
				{
					CloseHandle(hDirectory);
					hDirectory = INVALID_HANDLE;
				}
			} while(KvGotoNextKey(hKeyValues, false));
			KvGoBack(hKeyValues);
		}
	}
	CloseHandle(hKeyValues);
}

bool:CopyFile_NotTxt_OverWriteExisting(const String:sStartPath[], const String:sEndPath[], const String:sFileName[])
{
	decl String:sFullFromPath[256], String:sFullToPath[256];
	Format(sFullFromPath, sizeof(sFullFromPath), "%s/%s", sStartPath, sFileName);
	Format(sFullToPath, sizeof(sFullToPath), "%s/%s", sEndPath, sFileName);
	
	if(!FileExists(sFullFromPath))
	{
		LogError("Could not find file '%s' for function CopyFile_NotTxt_OverWriteExisting()", sFullFromPath);
		return false;
	}

	new vBuffer[2][15000];
	
	new Handle:hFile = OpenFile(sFullFromPath, "r");
	new Handle:hFileTemp = OpenFile(sFullToPath, "w");
	
	if(hFile != INVALID_HANDLE)
	{
		while(ReadFile(hFile, vBuffer[0], 1, 1))
		{
			WriteFile(hFileTemp, vBuffer[0], 1, 1);
		}
	}
	else
	{
		return false;
	}
	
	if(hFile != INVALID_HANDLE)
	{
		CloseHandle(hFile);
	}
	if(hFileTemp != INVALID_HANDLE)
	{
		CloseHandle(hFileTemp);
	}
	return true;
}

MoveFile(const String:sFromPath[], const String:sToPath[], const String:sFileName[])
{
	decl String:sFullFromPath[256];
	Format(sFullFromPath, sizeof(sFullFromPath), "%s/%s", sFromPath, sFileName);
	if(CopyFile_NotTxt_OverWriteExisting(sFromPath, sToPath, sFileName) == true)
	{
#if defined DEGUGMODE
		LogToFileEx(g_sDebugPath, "Deleting file after move: %s", sFullFromPath);
#endif
		DeleteFile(sFullFromPath);
	}
	else
	{
#if defined DEGUGMODE
		LogToFileEx(g_sDebugPath, "File move unsuccessful: %s", sFullFromPath);
#endif
	}
	return;
}

/*
///////////////////////////////////////////////////////////////////////////
//////////////////////////////// Changelog ////////////////////////////////
///////////////////////////////////////////////////////////////////////////

4.0:
	* Started Change log.
	* Coded in ability to move stuff, made days a float instead of an integer, gave option to accept "any" file extension
4.1:
	* Code updates.
4.2:
	* Code updated.
	* Changed debug mode to be upon compile only.
*/