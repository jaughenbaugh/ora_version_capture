CREATE OR REPLACE package pg_ver_capture as 

procedure capture_version
(p_owner in varchar2
,p_object in varchar2
,p_object_type in varchar2);

function vc_required
(p_owner in varchar2
,p_object in varchar2
,p_object_type in varchar2
,p_last_ddl_time in date)
return number;

end pg_ver_capture;
/
