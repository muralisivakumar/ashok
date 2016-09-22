package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;


import android.app.Activity;
import android.app.AlertDialog;
import android.content.ContentValues;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;

public class DispalyDetails extends Activity 
{
	LoginWebPage loginpage;

	String name,mail,phonenumber;
	SQLiteDatabase db;
	TextView fname,cmail,phone;
	ImageView image;
	ArrayList<Model> l1;
	byte[] img1;
	Bitmap b1;
	int pos;
	Button edit,save,salarydetails,productdetails;
	final Context context=this;
	 String newname,newemail,newphone;
	 String newName,newEmail,newPhone;
	 DatabaseHelper database=new DatabaseHelper(this);
	
	ArrayList<String> list=new ArrayList<String>();
	
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_dispaly_details);
		loginpage=new LoginWebPage();
		
		db=database.getWritableDatabase();
		db=database.getReadableDatabase();

	   fname=(TextView)findViewById(R.id.text1);
	   cmail=(TextView)findViewById(R.id.text2);
	  phone=(TextView)findViewById(R.id.text3);
	  image=(ImageView)findViewById(R.id.image);
	  
	  edit=(Button)findViewById(R.id.edit);
	  save=(Button)findViewById(R.id.save);
	  salarydetails=(Button)findViewById(R.id.SalaryDetails);
	  productdetails=(Button)findViewById(R.id.ProductDetails);

	   
	  
        
		String email = getIntent().getExtras().getString("EMAIL");
		System.out.println("mail id is"+email);
		
		//pos=getIntent().getExtras().getInt("Position");
		//pos=pos+1;
	
		//database.getData(email);

		//System.out.println("checking'''''''''''''''");
		
	//	 Cursor c = db.query("LoginInfo", new String[] {"USERNAME","EMAIL","PASSWORD","MOBILE"}, "EMAIL" + "=?",
	         //     new String[] { String.valueOf(email) }, null, null, null, null);
		
	     
		 Cursor c = db.rawQuery("SELECT IMAGE,USERNAME,EMAIL,MOBILE from LoginInfo WHERE EMAIL = '"+email+"'", null);   
		 
		 if(c!=null)
		 {
		 
		if(c.moveToFirst())
		{
			
			do {
				
				//Toast.makeText(getApplicationContext(), ""+c.getString(0), Toast.LENGTH_SHORT).show();
				 name=c.getString(1);
				 mail=c.getString(2);
				 phonenumber=c.getString(3);
				 img1=c.getBlob(0);
				 
				 b1=BitmapFactory.decodeByteArray(img1, 0, img1.length);
	                image.setImageBitmap(b1);
				fname.setText(name);
                cmail.setText(mail);
                phone.setText(phonenumber);
            //  l1.add(object);
            
			} while (c.moveToNext());
		}
		 }
		 
		 
		 
/*Cursor c1= db.rawQuery("SELECT IMAGE,USERNAME,EMAIL,MOBILE from LoginInfo WHERE ROWID = '"+pos+"'", null);   
		 
		 if(c1!=null)
		 {
		 
		if(c1.moveToFirst())
		{
			
			do {
				
				//Toast.makeText(getApplicationContext(), ""+c.getString(0), Toast.LENGTH_SHORT).show();
				 name=c1.getString(1);
				 mail=c1.getString(2);
				 phonenumber=c1.getString(3);
				 img1=c1.getBlob(0);
				 
				 b1=BitmapFactory.decodeByteArray(img1, 0, img1.length);
	                image.setImageBitmap(b1);
				fname.setText(name);
                cmail.setText(mail);
                phone.setText(phonenumber);
            //  l1.add(object);
            
			} while (c1.moveToNext());
		}
		 }*/
		 
		 
		 
		 
		 
		 
		 
		// Model model = l1.get(pos);
		
		// fname.setText(model.getName());
		/*while(c.moveToNext())
		{
			//list.add(c.getString(1)+c.getString(2)+c.getString(3));
			//System.out.println(list.toString());
			text.setText(c.getString(0)+"\t"+c.getString(1)+"\t"+c.getString(2)+"\t"+c.getString(3));
		}*/
		 edit.setOnClickListener(new OnClickListener() 
		 {
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				fname.setOnClickListener(new OnClickListener() 
				{
					
					@Override
					public void onClick(View v) 
					{
						// TODO Auto-generated method stub
						AlertDialog.Builder alert = new AlertDialog.Builder(context);
			            alert.setTitle("Alert Dialog With EditText"); //Set Alert dialog title here
			            alert.setMessage("Enter Your Name Here"); //Message here
			 
			            // Set an EditText view to get user input 
			            final EditText input = new EditText(context);
			            alert.setView(input);
			 
			            alert.setPositiveButton("OK", new DialogInterface.OnClickListener() 
			            {
			            public void onClick(DialogInterface dialog, int whichButton) 
			            {
			             //You will get as string input data in this variable.
			             // here we convert the input to a string and show in a toast.
			            newname = input.getEditableText().toString();
			            fname.setText(newname);
			            
			            // Toast.makeText(context,srt,Toast.LENGTH_LONG).show();                
			            } // End of onClick(DialogInterface dialog, int whichButton)
			        }); //End of alert.setPositiveButton
			            alert.setNegativeButton("CANCEL", new DialogInterface.OnClickListener() 
			            {
			              public void onClick(DialogInterface dialog, int whichButton) 
			              {
			                // Canceled.
			                  dialog.cancel();
			              }
			        }); //End of alert.setNegativeButton
			            
			            AlertDialog alertDialog = alert.create();
			            alertDialog.show();
			            
					}
				});
				
				cmail.setOnClickListener(new OnClickListener() 
				{
					
					@Override
					public void onClick(View arg0) 
					{
						// TODO Auto-generated method stub
						AlertDialog.Builder alert = new AlertDialog.Builder(context);
			            alert.setTitle("Alert Dialog With EditText"); //Set Alert dialog title here
			            alert.setMessage("Enter Your mail Here"); //Message here
			 
			            // Set an EditText view to get user input 
			            final EditText input1 = new EditText(context);
			            alert.setView(input1);
			 
			            alert.setPositiveButton("OK", new DialogInterface.OnClickListener() 
			            {
			            public void onClick(DialogInterface dialog, int whichButton) 
			            {
			             //You will get as string input data in this variable.
			             // here we convert the input to a string and show in a toast.
			            newemail = input1.getEditableText().toString();
			            cmail.setText(newemail);
			            
			            // Toast.makeText(context,srt,Toast.LENGTH_LONG).show();                
			            } // End of onClick(DialogInterface dialog, int whichButton)
			        }); //End of alert.setPositiveButton
			            alert.setNegativeButton("CANCEL", new DialogInterface.OnClickListener() 
			            {
			              public void onClick(DialogInterface dialog, int whichButton) 
			              {
			                // Canceled.
			                  dialog.cancel();
			              }
			        }); //End of alert.setNegativeButton
			            
			            AlertDialog alertDialog = alert.create();
			            alertDialog.show();
			            
					}
				});
				
				phone.setOnClickListener(new OnClickListener() 
				{
					
					@Override
					public void onClick(View arg0) 
					{
						// TODO Auto-generated method stub
						AlertDialog.Builder alert = new AlertDialog.Builder(context);
			            alert.setTitle("Alert Dialog With EditText"); //Set Alert dialog title here
			            alert.setMessage("Enter Your Mobile Number Here"); //Message here
			 
			            // Set an EditText view to get user input 
			            final EditText input1 = new EditText(context);
			            alert.setView(input1);
			 
			            alert.setPositiveButton("OK", new DialogInterface.OnClickListener() 
			            {
			            public void onClick(DialogInterface dialog, int whichButton) 
			            {
			             //You will get as string input data in this variable.
			             // here we convert the input to a string and show in a toast.
			            newphone = input1.getEditableText().toString();
			           phone.setText(newphone);
			           
			            // Toast.makeText(context,srt,Toast.LENGTH_LONG).show();                
			            } // End of onClick(DialogInterface dialog, int whichButton)
			        }); //End of alert.setPositiveButton
			            alert.setNegativeButton("CANCEL", new DialogInterface.OnClickListener() 
			            {
			              public void onClick(DialogInterface dialog, int whichButton) 
			              {
			                // Canceled.
			                  dialog.dismiss();
			              }
			        }); //End of alert.setNegativeButton
			            
			            AlertDialog alertDialog = alert.create();
			            alertDialog.show();
			          
			            
					}
				});
				newName=fname.getText().toString();
				newEmail=cmail.getText().toString();
				newPhone=phone.getText().toString();
				 
			}
		});
		 save.setOnClickListener(new OnClickListener() 
		 {
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				
				  updateContact(newName, newEmail, newPhone);
				
			}
		});
		 productdetails.setOnClickListener(new OnClickListener() 
		 {
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				Intent products=new Intent(DispalyDetails.this,ProductDetails.class);
				startActivity(products);
				
			}
		});
		 
		 
		 salarydetails.setOnClickListener(new OnClickListener()
		 {
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				Intent salarypage=new Intent(DispalyDetails.this,SalaryPage.class);
				startActivity(salarypage);
				
			}
		});
		
		 
		
}
	public boolean updateContact (String name,String mail,String phone)
	   {
	     db = database.getWritableDatabase();
	      ContentValues contentValues = new ContentValues();
	      contentValues.put("USERNAME", name);
	      contentValues.put("EMAIL", mail);
	      contentValues.put("MOBILE", phone);
	      System.out.println("updated values are:"+"\t"+name+"\t"+mail+"\t"+phone);
	      db.update("LoginInfo", contentValues, "USERNAME = ? ", new String[] {name} );
	      return true;
	   }
}
