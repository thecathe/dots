#!/usr/bin/env python

import os
# import sys
import json


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

  # 
  def get_db(self):
    assert "db.json" in os.listdir(self.__cwd)
    with open("db.json",'r') as file:
      self.__db = json.load(file)
      
    return self.__db
  
  # 
  def write_db(self):
    with open("db.json".'w') as file:
      file.write(self.get_db())
  
  #
  def get_tbd(self):
    if "tbd.json" in os.listdir(self.__cwd):
      # check for any to be deleted
      with open("tbd.json", 'r') as file:
        self.__tbd = json.load(file)
    else:
      # create default, empty file
      with open("tbd.json", 'w') as file:
        file.write("[]")
      self.__tbd = []
    
    return self.__tbd

  #
  def __init__(self):

    # load .jsons
    self.get_db()      
    self.get_tbd()
    
  #
  def to_string(self):
    return f"tbd: {self.get_tbd()};\ndb: {json.dumps(self.get_db(),sort_keys=True,indent=2)}.\n"
  
  #
  def process_tbd(self):
    tbd = self.get_tbd()
    
    for d in tbd:
      # check if in cwd and remove
      # and then remove from db, and update
      
      pass
    print("mgr.process_tbd() unfinished: warning, skipped.")

# when running file
if __name__=='__main__':
  
  # # get args, handle startup flags
  # args = {}
  # for arg in sys.argv[1:]:
  #     if arg == ""
  
  # create new manager
  m = mgr()
  
  # process those marked for deletion
  mgr.process_tbd()
