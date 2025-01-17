#!/usr/bin/env python

import os
import sys
import pathlib
import datetime
import json

# https://stackoverflow.com/a/18489147
from inspect import getsourcefile

#
def default_do_backup():
  return True

#
def default_do_rebase():
  return False

#
def default_do_refresh():
  return False

#
def default_do_setup():
  return True

#
def default_do_not_push():
  return False

# object for managing the db.json file
class mgr():

  # Serves as the \"database\" (hence `db`) for dot-file management tool.
  # The `scripts` list specifies the files to be backed-up from `~/bin/`.
  # By default, any disparity between `scripts` and `~/bin/` will be
  # resolved by adding it to the other directory. In order to actually
  # remove an item from both, mark it for deletion using
  # `marked-for-deletion.json` (if missing, this is automatically generated
  # when running the tool). The `configs` list is similar but for `~/.config/`.
  # The list `backups` contains other items to be backed-up, requiring more specific information.
  __db = {}
  __tbd = []

  __cwd = os.path.split(os.path.abspath(getsourcefile(lambda:0)))[0] #os.getcwd()

  __do_backup = default_do_backup()
  __do_rebase = default_do_rebase()
  __do_refresh = default_do_refresh()
  __do_setup = default_do_setup()
  __do_not_push = default_do_not_push()

  #
  def get_db(self):
    print(f"cwd: {self.__cwd}.")
    assert "db.json" in os.listdir(self.__cwd)
    with open(os.path.join(self.__cwd,"db.json"), "r") as file:
      self.__db = json.load(file)

    return self.__db

  #
  def write_db(self):
    with open(os.path.join(self.__cwd,"db.json"), "w") as file:
      file.write(self.get_db())

  #
  def get_tbd(self):
    if "tbd.json" in os.listdir(self.__cwd):
      # check for any to be deleted
      with open(os.path.join(self.__cwd,"tbd.json"), "r") as file:
        self.__tbd = json.load(file)
    else:
      # create default, empty file
      with open(os.path.join(self.__cwd,"tbd.json"), "w") as file:
        file.write("[]")
      self.__tbd = []

    return self.__tbd

  #
  def __init__(self, args):

    # print(f"new mgr in {self.__cwd}.")

    # load .jsons
    self.get_db()
    self.get_tbd()

    # parse args
    self.__do_backup = args.get("backup", default_do_backup())
    self.__do_rebase = args.get("rebase", default_do_rebase())
    self.__do_refresh = args.get("refresh", default_do_refresh())
    self.__do_setup = args.get("setup", default_do_setup())
    self.__do_not_push = args.get("dontpush", default_do_not_push())

    # sanity check -- this would be pointless
    assert not (self.__do_backup and self.__do_refresh)

  #
  def to_string(self):
    return f"do backup: {self.__do_backup}; do rebase: {self.__do_rebase}; do refresh: {self.__do_refresh}; do setup: {self.__do_setup};\ntbd: {self.get_tbd()};\ndb: {json.dumps(self.get_db(),sort_keys=True,indent=2)}.\n"

  #
  def validate_dirs(self):

    # make the necessary directories
    pathlib.Path(f"{self.__cwd}/scripts").mkdir(parents=True, exist_ok=True)

    print("\nvalidating repo config dirs...")
    for c in self.__db["configs"]:
      assert c[0:10]=="~/.config/"
      local_dir = f"{self.__cwd}/configs{c[9:c.rfind(os.path.basename(c))]}"
      print(f"(config) local_dir: {local_dir}.")
      pathlib.Path(local_dir).mkdir(parents=True, exist_ok=True)

    print("\nvalidating repo backup dirs...")
    for b in self.__db["backups"]:
      assert "path" in b.keys()
      dirpath = b["path"][1:] if b["path"][0:1] in [".","~"] else b["path"]
      local_dir = f"{self.__cwd}/backups{dirpath[:dirpath.rfind(os.path.basename(dirpath))]}"
      print(f"(backup) local_dir: {local_dir}.")
      pathlib.Path(local_dir).mkdir(parents=True, exist_ok=True)

    print("\nfinished validating dirs.\n")

  # TODO: add mechanism to stop backing things up and to, when necessary, delete files from this repo automatically
  # def process_tbd(self):
  #   tbd = self.get_tbd()

  #   for d in tbd:
  #     # check if in cwd and remove
  #     # and then remove from db, and update

  #     pass
  #   print("mgr.process_tbd, unfinished: warning, skipped.")

  #
  def backup_dir(self,_dir_path:str,_backup_path:str):
    _dir_path = f"{f"{pathlib.Path.home()}{_dir_path[1:]}"if _dir_path[0]=="~" else _dir_path}{""if _dir_path[-1]=="/" else "/"}"

    with os.scandir(_dir_path) as it:
      for entry in it:
        system_path = f"{entry.path}"
        backup_path = f"{_backup_path}{entry.name}"
        if entry.is_file():
          os.system(f"cp {system_path} {backup_path}")
        else:
          backup_path = f"{backup_path}/"
          pathlib.Path(backup_path).mkdir(parents=True, exist_ok=True)
          self.backup_dir(system_path,backup_path)

  #
  def run(self):

    if self.__do_setup:

      print(f"setting up script to allow maintenance of this repo to be more easily handled.")
      input("\npress any key to continue...")

      # copy first
      os.system(f"cp {self.__cwd}/run_dot_manager.sh {self.__cwd}/_run_dot_manager.sh")
      new_lines = []

      # alter line to point back to here
      with open(os.path.join(self.__cwd,"_run_dot_manager.sh"),"r") as file:
        default_lines = file.readlines()
        print(f"default lines: {default_lines}")
        assert 'maintainerPath=$"maintain.py"\n' in default_lines

        for l in default_lines:
          if l=='maintainerPath=$"maintain.py"\n':
            new_lines.append(f"## last updated: {datetime.datetime.now()}\n")
            new_lines.append(f"maintainerPath=$\"{self.__cwd}/maintain.py\"\n")
          else:
            new_lines.append(l)

      with open(os.path.join(self.__cwd,"_run_dot_manager.sh"),"w") as file:
        file.writelines(new_lines)

      # move
      os.system(f"mv {self.__cwd}/_run_dot_manager.sh ~/bin/run_dot_manager.sh")

    if self.__do_rebase:

      print(f"rebasing repo.")
      input("\npress any key to continue...")

      os.system(f"cd {self.__cwd}; git config pull.rebase true; git pull --tags origin main")

    # from repo -> to system
    if self.__do_refresh:

      print(f"\nrefreshing system configs with those in: {self.__cwd}/configs...")
      input("\npress any key to continue...")

      for c in self.__db["configs"]:
        assert c[0:10]=="~/.config/"
        system_path = f"{c}"
        if pathlib.Path.exists(system_path):
          backup_path = f"{self.__cwd}/configs{c[9:]}"
          os.system(f"cp {backup_path} {system_path}")
        else:
          print(f"(configs) not found, untouched: {system_path}.")

      print(f"\nrefreshing system backups with those in: {self.__cwd}/backups...")
      input("\npress any key to continue...")

      for b in self.__db["backups"]:
        assert "path" in b.keys()
        system_path = f"{b["path"]}"
        if pathlib.Path.exists(system_path):
          backup_path = f"{self.__cwd}/backups{b["path"][1:] if b["path"][0:1] in [".","~"] else b["path"]}"
          os.system(f"cp {backup_path} {system_path}")
        else:
          print(f"(backups) not found, untouched: {system_path}.")

      print(f"\nrefreshing system scripts with those in: {self.__cwd}/scripts...")
      input("\npress any key to continue...")

      for s in self.__db["scripts"]:
        system_path = f"~/bin/{s}"
        backup_path = f"{self.__cwd}/scripts/{s}"
        os.system(f"cp {backup_path} {system_path}")

      print("\nfinished running backup. (configs, backups, scripts)\n")


    # from system -> to repo
    if self.__do_backup:

      print(f"\nbacking up configs to: {self.__cwd}/configs...")
      input("\npress any key to continue...")

      for c in self.__db["configs"]:
        assert c[0:10]=="~/.config/"
        system_path = f"{c}"
        backup_path = f"{self.__cwd}/configs{c[9:]}"
        os.system(f"cp {system_path} {backup_path}")

      print(f"\nbacking up backups to: {self.__cwd}/backups...")
      input("\npress any key to continue...")

      for b in self.__db["backups"]:
        if b.get("ignore",False) or b.get("never_backup",False):
          print(f"(ignoring: {b["path"]})")
        else:
          assert "path" in b.keys()
          if b.get("is_directory",False):
            system_path = f"{b["path"]}"
            backup_path = f"{self.__cwd}/backups{b["path"][1:] if b["path"][0:1] in [".","~"] else b["path"]}"
            self.backup_dir(system_path,backup_path)
          else:
            system_path = f"{b["path"]}"
            backup_path = f"{self.__cwd}/backups{b["path"][1:] if b["path"][0:1] in [".","~"] else b["path"]}"
            os.system(f"cp {system_path} {backup_path}")

      print(f"\nbacking up scripts to: {self.__cwd}/scripts...")
      input("\npress any key to continue...")

      for s in self.__db["scripts"]:
        system_path = f"~/bin/{s}"
        backup_path = f"{self.__cwd}/scripts/{s}"
        os.system(f"cp {system_path} {backup_path}")

      print("\nfinished running backup. (configs, backups, scripts)\n")

      if self.__do_not_push:
        print("warning, nothing has been pushed to git. this will all be undone if run again with rebase.")

      else:
        commit_input = input("\n(optional) enter commit message: ")
        commit_msg = "(auto) maintenance backup." if (commit_input=="") else f"{commit_input}"
        print("\n")

        os.system(f"cd {self.__cwd}; git add -A && git commit -m \"{commit_msg}\"")

        # push to git
        input("\npress any key to push...")
        os.system(f"cd {self.__cwd}; git push --tags origin main")


      print("\nfinished pushing changes to git.\n")


#
def default_args():
  return {"backup":default_do_backup(),"rebase":default_do_rebase(),"refresh":default_do_refresh(),"setup":default_do_setup(),"dontpush":default_do_not_push()}



# when running file
if __name__=='__main__':

  # get args, handle startup flags
  args = default_args()
  for arg in sys.argv[1:]:
    # special case
    if arg == "nobackup":
      args["backup"] = False
    # otherwise, set arg to true
    elif arg in args.keys():
      args[arg] = True

  # create new manager
  m = mgr(args)
  print(f"\nmgr: {m.to_string()}")

  # ensure correct dir structure
  m.validate_dirs()

  # # process those marked for deletion
  # m.process_tbd()

  #
  m.run()
  print("\nmaintenance finished.\n")
