package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

public class DatabaseHelper extends SQLiteOpenHelper 
{
	public DatabaseHelper(Context context) 
	{
		super(context, "UserInfo_DB", null, 1);
		// TODO Auto-generated constructor stub
	}
	 ArrayList<String> list=new ArrayList<String>();

	@Override
	public void onCreate(SQLiteDatabase db) 
	{
		// TODO Auto-generated method stub
		
		String TABLE="CREATE TABLE LoginInfo(ROWID INTEGER PRIMARY KEY AUTOINCREMENT,USERNAME TEXT,EMAIL TEXT,PASSWORD TEXT,MOBILE TEXT,IMAGE BLOB);";
		db.execSQL(TABLE);
		
		String TABLE1="CREATE TABLE SalaryInfo(USERID INTEGER PRIMARY KEY,MONTH TEXT,SALARY TEXT,JOINEDDATE TIMESTAMP);";
		db.execSQL(TABLE1);
		
		String TABLE2="CREATE TABLE ProductInfo(PID INTEGER NOT NULL PRIMARY KEY  AUTOINCREMENT,PRODUCTNAME TEXT,PURCHASEDATE TIMESTAMP);";
		db.execSQL(TABLE2);
		
		String TABLE3="CREATE TABLE AddressInfo(ADRESSID INTEGER PRIMARY KEY,PID INTEGER,STREET TEXT,SHIPPINGDATE TIMESTAMP,CONSTRAINT addressid FOREIGN KEY(PID) REFERENCES ProductInfo(PID));";
	     db.execSQL(TABLE3);
	     
	     String TABLE4="CREATE TABLE ActivityInfo(ROWID INTEGER PRIMARY KEY AUTOINCREMENT,USERID INTEGER,PID INTEGER,ADRESSID INTEGER,RECEIVEDTIME TIMESTAMP);";
	     db.execSQL(TABLE4);
	
	}

	@Override
	public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) 
	{
		// TODO Auto-generated method stub
		
	}
	
	public void InsertValues(String USERNAME,String EMAIL,String PASSWORD,String MOBILE,byte[] IMAGE)
	{
		SQLiteDatabase database=this.getWritableDatabase();
		ContentValues contentValues=new ContentValues();
		contentValues.put("USERNAME", USERNAME);
		contentValues.put("EMAIL", EMAIL);
		contentValues.put("PASSWORD", PASSWORD);
		contentValues.put("MOBILE", MOBILE);
		contentValues.put("IMAGE", IMAGE);

		database.insert("LoginInfo", null, contentValues);
	}
public void insertSalaryDetails(String USERID,String MONTH,String SALARY,String DATE)
{
	SQLiteDatabase database=this.getWritableDatabase();
	ContentValues contentValues=new ContentValues();
	
	contentValues.put("USERID", USERID);

	contentValues.put("MONTH", MONTH);
	contentValues.put("SALARY", SALARY);
	contentValues.put("JOINEDDATE", DATE);
	

	database.insert("SalaryInfo", null, contentValues);
}


public void insertProductDetails(String PRODUCTNAME,String PURCHASEDATE)
{
	SQLiteDatabase database=this.getWritableDatabase();
	ContentValues contentValues=new ContentValues();
	
	contentValues.put("PRODUCTNAME",PRODUCTNAME);
	contentValues.put("PURCHASEDATE",PURCHASEDATE);
     
	database.insert("ProductInfo", null, contentValues);
	
}


public void insertAdressDetails(String PID,String ADRESSID,String STREET,String SHIPPINGDATE)
{
	SQLiteDatabase database=this.getWritableDatabase();
	ContentValues contentValues=new ContentValues();
	contentValues.put("PID",PID);
	contentValues.put("STREET",STREET);
	contentValues.put("SHIPPINGDATE",SHIPPINGDATE);
	contentValues.put("ADRESSID",ADRESSID);

	
	database.insert("AddressInfo", null, contentValues);
	
}

public void insertActivityDetails(String USERID,String PID,String ADRESSID,String RECEIVEDTIME)
{
	SQLiteDatabase database=this.getWritableDatabase();
	ContentValues contentValues=new ContentValues();
	
	contentValues.put("USERID",USERID);

	contentValues.put("PID",PID);
	contentValues.put("ADRESSID",ADRESSID);
	contentValues.put("RECEIVEDTIME",RECEIVEDTIME);
	
	database.insert("ActivityInfo", null, contentValues);
}


	public Cursor getData(String id)
	 {
	      SQLiteDatabase db = this.getReadableDatabase();
	      Cursor c = db.rawQuery("SELECT * FROM  LoginInfo WHERE EMAIL = '"+id+"'", null);     
			 
			if(c.moveToFirst()){
				
				do {
					
				list.add(c.getString(0)+"\t"+c.getString(1)+"\t"+c.getString(2)+"\t"+c.getString(3));	
				
				} while (c.moveToNext());
			};
			return c;
}
	
	public Cursor getSalaryData(String id)
	 {
	      SQLiteDatabase db = this.getReadableDatabase();
	      Cursor c = db.rawQuery("SELECT * FROM  SalaryInfo WHERE JOINEDDATE= '"+id+"'", null);     
			 
			if(c.moveToFirst()){
				
				do {
					
				list.add(c.getString(0)+"\t"+c.getString(1)+"\t"+c.getString(2)+"\t"+c.getString(3));	
				
				} while (c.moveToNext());
			};
			return c;
	 }
}
