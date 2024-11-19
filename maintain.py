#!/usr/bin/env python

import os
import sys
import pathlib
import json

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
  return False

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

  __cwd = os.getcwd()

  __do_backup = default_do_backup()
  __do_rebase = default_do_rebase()
  __do_refresh = default_do_refresh()
  __do_setup = default_do_setup()
  __do_not_push = default_do_not_push()

  #
  def get_db(self):
    assert "db.json" in os.listdir(self.__cwd)
    with open("db.json", "r") as file:
      self.__db = json.load(file)

    return self.__db

  #
  def write_db(self):
    with open("db.json", "w") as file:
      file.write(self.get_db())

  #
  def get_tbd(self):
    if "tbd.json" in os.listdir(self.__cwd):
      # check for any to be deleted
      with open("tbd.json", "r") as file:
        self.__tbd = json.load(file)
    else:
      # create default, empty file
      with open("tbd.json", "w") as file:
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

  # #
  # def process_tbd(self):
  #   tbd = self.get_tbd()

  #   for d in tbd:
  #     # check if in cwd and remove
  #     # and then remove from db, and update

  #     pass
  #   print("mgr.process_tbd, unfinished: warning, skipped.")

  #
  def run(self):

    if self.__do_setup:
      print(f"setting up script to allow maintenance of this repo to be more easily handled.")

      # copy first
      os.system(f"cp ./dotmgr.sh ./_dotmgr.sh")
      new_lines = []

      # alter line to point back to here
      with open("_dotmgr.sh","r") as file:
        default_lines = file.readlines()
        print(f"default lines: {default_lines}")
        # assert 'maintainerPath=$"maintain.py"' in default_lines

        for l in default_lines:
          if l=='maintainerPath=$"maintain.py"':
            new_lines.append(f"maintainerPath=$\"{self.__cwd}maintain.py\"")
          else:
            new_lines.append(l)

      with open("_dotmgr.sh","w") as file:
        file.writelines(new_lines)

      # move
      print(f"test: {f"mv {self.__cwd}_dotmgr.sh ~/bin/dotmgr.sh"}")
      # os.system(f"mv {self.__cwd}_dotmgr.sh ~/bin/dotmgr.sh")

    if self.__do_rebase:
      print(f"rebasing repo.")
      os.system("git config pull.rebase true; git pull --tags origin main")

    # from repo -> to system
    if self.__do_refresh:

      print(f"\nrefreshing system configs with those in: {self.__cwd}/configs...")
      for c in self.__db["configs"]:
        assert c[0:10]=="~/.config/"
        local_path = f"{c}"
        if pathlib.Path.exists(local_path):
          backup_path = f"{self.__cwd}/configs{c[9:]}"
          os.system(f"cp {backup_path} {local_path}")
        else:
          print(f"(configs) not found, untouched: {local_path}.")

      print(f"\nrefreshing system backups with those in: {self.__cwd}/backups...")
      for b in self.__db["backups"]:
        assert "path" in b.keys()
        local_path = f"{b["path"]}"
        if pathlib.Path.exists(local_path):
          backup_path = f"{self.__cwd}/backups{b["path"][1:] if b["path"][0:1] in [".","~"] else b["path"]}"
          os.system(f"cp {backup_path} {local_path}")
        else:
          print(f"(backups) not found, untouched: {local_path}.")

      print(f"\nrefreshing system scripts with those in: {self.__cwd}/scripts...")
      for s in self.__db["scripts"]:
        local_path = f"~/bin/{s}"
        backup_path = f"{self.__cwd}/scripts/{s}"
        os.system(f"cp {backup_path} {local_path}")

      print("\nfinished running backup. (configs, backups, scripts)\n")


    # from system -> to repo
    if self.__do_backup:

      print(f"\nbacking up configs to: {self.__cwd}/configs...")
      for c in self.__db["configs"]:
        assert c[0:10]=="~/.config/"
        local_path = f"{c}"
        backup_path = f"{self.__cwd}/configs{c[9:]}"
        os.system(f"cp {local_path} {backup_path}")

      print(f"\nbacking up backups to: {self.__cwd}/backups...")
      for b in self.__db["backups"]:
        if b.get("ignore",False):
          print(f"(ignoring: {b["path"]})")
        else:
          assert "path" in b.keys()
          local_path = f"{b["path"]}"
          backup_path = f"{self.__cwd}/backups{b["path"][1:] if b["path"][0:1] in [".","~"] else b["path"]}"
          os.system(f"cp {local_path} {backup_path}")

      print(f"\nbacking up scripts to: {self.__cwd}/scripts...")
      for s in self.__db["scripts"]:
        local_path = f"~/bin/{s}"
        backup_path = f"{self.__cwd}/scripts/{s}"
        os.system(f"cp {local_path} {backup_path}")

      print("\nfinished running backup. (configs, backups, scripts)\n")

      if self.__do_not_push:
        print("warning, nothing has been pushed to git. this will all be undone if run again with rebase.")

      else:
        # push to git
        os.system(f"git add -A && git commit -m \"automatic backup during maintenance.\"")

        input("\npress any key to push...")
        os.system(f"git push --tags origin main")


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
