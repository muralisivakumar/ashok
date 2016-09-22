package com.example.administrator.databaseregistrationapp;



import android.content.Context;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.Gallery;
import android.widget.ImageView;



public class AddImgAdp extends BaseAdapter 
{

	private Context mContext;

    private Integer[] mImageIds = {
            R.drawable.baby1,
            R.drawable.baby1,
            R.drawable.baby1,
            R.drawable.baby1,
            R.drawable.baby1,
            R.drawable.baby1
          
             };

    public AddImgAdp(Context context) 
    {
        mContext = context;
    }

    public int getCount()
    {
        return mImageIds.length;
    }

    public Object getItem(int position)
    {
        return position;
    }

    public long getItemId(int position) 
    {
        return position;
    }


    // Override this method according to your need
    public View getView(int index, View view, ViewGroup viewGroup) 
    {
        // TODO Auto-generated method stub
        ImageView i = new ImageView(mContext);

        i.setImageResource(mImageIds[index]);
        i.setLayoutParams(new Gallery.LayoutParams(200, 200));
    
        i.setScaleType(ImageView.ScaleType.FIT_XY);

        return i;
}


}
