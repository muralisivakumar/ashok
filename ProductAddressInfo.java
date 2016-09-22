package com.example.administrator.databaseregistrationapp;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;

public class ProductAddressInfo extends Activity 
{
   EditText Userid;
   Button search;
   String UserId;
   SharedPreferences sh_Pref;
	SharedPreferences.Editor toEdit;
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_product_address_info);
		Userid=(EditText)findViewById(R.id.userid);
		search=(Button)findViewById(R.id.submit);
		
		search.setOnClickListener(new OnClickListener() 
		{
			
			@Override
			public void onClick(View v) 
			{
				// TODO Auto-generated method stub
				UserId=Userid.getText().toString();
				
				sh_Pref = getSharedPreferences("USERID Details", MODE_PRIVATE);
				toEdit = sh_Pref.edit();
				
				toEdit.putString("USERID",UserId);
				toEdit.commit();
			}
		});
}
}