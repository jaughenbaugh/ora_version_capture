CREATE OR REPLACE package body pg_ver_capture as
--------------------------------------------------------------------------------
function CLOB_TO_BLOB (p_clob CLOB) return BLOB
as
 l_blob          blob;
 l_dest_offset   integer := 1;
 l_source_offset integer := 1;
 l_lang_context  integer := DBMS_LOB.DEFAULT_LANG_CTX;
 l_warning       integer := DBMS_LOB.WARN_INCONVERTIBLE_CHAR;
BEGIN

  DBMS_LOB.CREATETEMPORARY(l_blob, TRUE);
  DBMS_LOB.CONVERTTOBLOB
  (
   dest_lob    =>l_blob,
   src_clob    =>p_clob,
   amount      =>DBMS_LOB.LOBMAXSIZE,
   dest_offset =>l_dest_offset,
   src_offset  =>l_source_offset,
   blob_csid   =>DBMS_LOB.DEFAULT_CSID,
   lang_context=>l_lang_context,
   warning     =>l_warning
  );
  return l_blob;
END;
--------------------------------------------------------------------------------
procedure capture_version
(p_owner in varchar2
,p_object in varchar2
,p_object_type in varchar2) 
as
  l_owner           all_objects.owner%type;
  l_object          all_objects.object_name%type;
  l_object_type     all_objects.object_type%type;
  no_owner_defined  exception;
  
  type vc_data_t is table of pg_vc_data%rowtype;
  vc_data vc_data_t;
  
  l_zip_file blob;
  l_file_name varchar2(1000);
  l_user_name varchar2(100);
  
begin
  
  delete from pg_vc_data;
  
  if p_owner is null then 
    raise no_owner_defined;
  else 
    l_owner := upper(p_owner);
  end if;
  
  l_object      := upper(nvl(p_object,'%'));
  l_object_type := upper(nvl(p_object_type,'%'));
  
  SELECT  null,
          OWNER,
          OBJECT_NAME,
          replace(OBJECT_TYPE,' ','_') object_type,
          LAST_DDL_TIME,
          null,
          to_clob(dbms_metadata.get_ddl(replace(OBJECT_TYPE,' ','_')
                                       ,OBJECT_NAME
                                       ,OWNER)) VC_CODE,
          null
  bulk collect into vc_data
  FROM    SYS.all_objects
  where   owner = p_owner
    and   object_type in ('TABLE', 'VIEW', 'SEQUENCE', 'PROCEDURE', 'FUNCTION', 
                          'PACKAGE', 'TYPE', 'TYPE BODY', 
                          'TRIGGER', 'SYNONYM', 'MATERIALIZED VIEW')
    and   object_name like nvl(p_object,'%')
    and   object_type like nvl(p_object_type,'%')
    and   pg_ver_capture.vc_required(owner, object_name, object_type, last_ddl_time) = 1
  order by object_type, object_name;
  
  forall indx in 1..vc_data.count
  insert into pg_vc_data
  values vc_data(indx);
/*  --> UNCOMMENT ONLY IF APEX V5 OR GREATER IS INSTALLED
  for idx in 1..vc_data.count loop
    apex_zip.add_file 
   (p_zipped_blob => l_zip_file,
    p_file_name   => lower(replace(vc_data(idx).obj_type,' ','_')||'/'||vc_data(idx).object||'.pls'),
    p_content     => CLOB_TO_BLOB(vc_data(idx).code));
  end loop;
  
  apex_zip.finish (p_zipped_blob => l_zip_file );
  
  l_user_name := lower(user);
  l_file_name := l_user_name||'.vc_data.'||to_char(sysdate,'YYYYMMDDHH24MISS');
  
  insert into pg_vc_zip
  (date_file
  ,file_content
  ,file_name)
  values
  (sysdate
  ,l_zip_file
  ,l_file_name);
*/    --> UNCOMMENT ONLY IF APEX V5 OR GREATER IS INSTALLED
exception 
  when no_owner_defined then
    raise;
  when others then 
    raise;
end capture_version;
--------------------------------------------------------------------------------
end pg_ver_capture;
/
